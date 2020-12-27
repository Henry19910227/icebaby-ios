//
//  ICChatManager.swift
//  Icebaby
//
//  Created by 廖冠翰 on 2020/12/8.
//

import UIKit
import SwiftCentrifuge
import RxCocoa
import RxSwift
import SwiftyJSON

class ICChatManager: NSObject {
    static let shard = ICChatManager(userManager: ICUserManager(),
                                     chatAPIService: ICChatAPIService(userManager: ICUserManager()))
    private lazy var client: CentrifugeClient = {
        let url = "ws://127.0.0.1:8000/connection/websocket?format=protobuf"
        let client = CentrifugeClient(url: url, config: CentrifugeClientConfig(), delegate: self)
        return client
    }()
    
    //DI
    private let userManager: UserManager
    private let chatAPIService: ICChatAPI
    
    //Tool
    private let dateFormatter = ICDateFormatter()
    
    //Data
    private var currentSubscribe: [String: CentrifugeSubscription] = [:]
    private var history:[String: [ICChatData]] = [:]
    private var unreadDict: [String: Int] = [:]
    private var readDateDict: [String: Date] = [:]
    private var channels: [ICChannel] = []
    
    //Rx
    private let disposeBag = DisposeBag()
    
    //Input
    public let sendMessage = PublishSubject<(String, Data?)>()
    
    //Output
    public let onPublish = PublishSubject<ICChatData?>()
    public let subscribe = PublishSubject<String>()
    public let onSubscribeSuccess = PublishSubject<(String, [ICChatData])>()
    public let onSubscribeError = PublishSubject<String>()
    public let unreadCount = PublishSubject<(String, Int)>()
    
    init(userManager: UserManager,
         chatAPIService: ICChatAPI) {
        self.userManager = userManager
        self.chatAPIService = chatAPIService
        super.init()
        bindSendMessage(sendMessage.asDriver(onErrorJustReturn: ("", nil)))
    }
}

//MARK: - Public
extension ICChatManager: APIDataTransform {
    public func connect(token: String, uid: Int) {
        client.setToken(token)
        client.connect()
        subscribeChannel(String(uid))
    }
    
    public func updateReadDate(_ readDate: Date, channelID: String) {
        guard let chatDatas = history[channelID] else { return }
        guard readDateDict[channelID] != nil else { return }
        
        //更新已讀時間
        readDateDict[channelID] = readDate
        
        //計算未讀訊息數量
        let myLastReadDate = self.getMyLastReadDate(channelID: channelID)
        let unreadCount = self.getUnreadCount(channelID: channelID,
                                              lastReadDate: myLastReadDate,
                                              chatDatas: chatDatas)
        self.unreadDict[channelID] = unreadCount
    }
    
    public func mychannels(onSuccess: @escaping ([ICChannel]) -> Void,
                           onError: @escaping (Error) -> Void) {
        chatAPIService
            .apiGetMyChannel()
            .do(afterSuccess: { [unowned self] (channels) in
                self.channels = channels
            })
            .subscribe(onSuccess: { (channels) in
                onSuccess(channels)
            }, onError: { (error) in
                onError(error)
            })
            .disposed(by: disposeBag)
    }
    
    public func subscribe(channelID: String) {
        self.subscribeChannel(channelID)
    }
    
    // 獲取歷史訊息
    public func history(channelID: String, completion: @escaping ([ICChatData]) -> Void) {
        if let chatDatas = history[channelID] {
            completion(chatDatas)
            return
        }
        apiHistory(channelID: channelID) { [unowned self] (datas) in
            self.history[channelID] = datas
            completion(datas)
        }
        
//        let sub = currentSubscribe[channelID]
//        sub?.history(completion: { [unowned self] (pubs, error) in
//            guard let pubs = pubs else {
//                completion([ICChatData]())
//                return
//            }
//            let jsons = pubs.map { (pub) -> JSON in
//                do {
//                    return try JSON(data: pub.data)
//                } catch {
//                    return JSON()
//                }
//            }
//            let chatDatas = dataDecoderArrayTransform(ICChatData.self, jsons)
//            history[channelID] = chatDatas
//            completion(chatDatas)
//        })
    }
}

//MARK: - Bind
extension ICChatManager {
    private func bindSendMessage(_ sendMessage: Driver<(String, Data?)>) {
        sendMessage
            .filter({ [unowned self] (channelID, data) -> Bool in
                return data != nil && self.currentSubscribe[channelID] != nil
            })
            .map({ [unowned self] (channelID, data) -> (CentrifugeSubscription, Data) in
                return (self.currentSubscribe[channelID]!, data!)
            })
            .drive(onNext: { (sub, data) in
                sub.publish(data: data) { (error) in
                    guard let error = error else { return }
                    print("publish error: \(error.localizedDescription)")
                }
            })
            .disposed(by: disposeBag)
    }
}
 
//MARK: - CentrifugeClientDelegate
extension ICChatManager: CentrifugeClientDelegate {
    func onConnect(_ client: CentrifugeClient, _ event: CentrifugeConnectEvent) {
    
    }
}

//MARK: - CentrifugeSubscriptionDelegate
extension ICChatManager: CentrifugeSubscriptionDelegate {
    func onPublish(_ sub: CentrifugeSubscription, _ event: CentrifugePublishEvent) {
        do {
            let data = try JSONDecoder().decode(ICChatData.self, from: event.data)
            if data.type == "message" {
                //將新訊息存入歷史訊息中
                history[data.channelId ?? ""]?.append(data)
                
                //將未讀個數 + 1
                if let unreadCount = unreadDict[data.channelId ?? ""], data.message?.uid ?? 0 != userManager.uid() {
                    let currentUnreadCount = (unreadCount + 1)
                    unreadDict[data.channelId ?? ""] = currentUnreadCount
                    self.unreadCount.onNext((sub.channel, currentUnreadCount))
                }
            }
            onPublish.onNext(data)
        } catch {
            print("Error!")
        }
    }
    
    func onSubscribeSuccess(_ sub: CentrifugeSubscription, _ event: CentrifugeSubscribeSuccessEvent) {
        currentSubscribe[sub.channel] = sub
        if userManager.uid() == Int(sub.channel) {
            print("subscribe user channel \(sub.channel)")
            return
        }
        history(channelID: sub.channel) { [unowned self] (datas) in
            //計算未讀訊息數量
            let myLastReadDate = self.getMyLastReadDate(channelID: sub.channel)
            let unreadCount = self.getUnreadCount(channelID: sub.channel,
                                                  lastReadDate: myLastReadDate,
                                                  chatDatas: datas)
            self.unreadDict[sub.channel] = unreadCount
            
            //發送未讀數量訊號
            self.unreadCount.onNext((sub.channel, unreadCount))
            
            //第一次成功訂閱通知
            print("subscribe channel \(sub.channel) success")
            self.onSubscribeSuccess.onNext((sub.channel, datas))
        }
        
    }
    
    func onSubscribeError(_ sub: CentrifugeSubscription, _ event: CentrifugeSubscribeErrorEvent) {
        onSubscribeError.onNext("subscribe channel \(sub.channel) error")
    }
}

//MARK: - Other
extension ICChatManager {
    public func subscribeChannel(_ channel: String?) {
        guard let channel = channel else { return }
        //已訂閱此channel
        if currentSubscribe[channel] != nil {
            onSubscribeSuccess.onNext((channel, history[channel] ?? []))
            unreadCount.onNext((channel, unreadDict[channel] ?? 0))
            return
        }
        var subscribeItem: CentrifugeSubscription?
        do {
            subscribeItem = try client.newSubscription(channel: channel, delegate: self)
        } catch {
            onSubscribeError.onNext(error.localizedDescription)
        }
        subscribeItem?.subscribe()
        
    }
}

//MARK: - Unread
extension ICChatManager {
    /** 計算並獲取未讀訊息個數*/
    private func getUnreadCount(channelID: String, lastReadDate: Date?, chatDatas: [ICChatData]) -> Int {
        var unreadCount = 0
        guard let lastReadDate = lastReadDate else { return 0 }
        for chatData in chatDatas {
            if userManager.uid() != chatData.message?.uid ?? 0 {
                let date = dateFormatter.dateStringToDate(chatData.message?.date ?? "", "yyyy-MM-dd HH:mm:ss") ?? Date()
                if dateFormatter.date(lastReadDate, earlierThan: date) {
                    unreadCount += 1
                }
            }
        }
        unreadDict[channelID] = unreadCount
        return unreadCount
    }
    
    /** 取得個人在指定頻道中最後讀取訊息時間*/
    private func getMyLastReadDate(channelID: String) -> Date? {
        if let readDate = readDateDict[channelID] { return readDate }
        var readTime: String?
        for channel in self.channels {
            for member in channel.members ?? [] {
                if self.userManager.uid() == member.userID {
                    readTime = member.readAt
                }
            }
        }
        guard let read = readTime else { return nil }
        let lastReadDate = dateFormatter.dateStringToDate(read, "yyyy-MM-dd HH:mm:ss")
        readDateDict[channelID] = lastReadDate
        return lastReadDate
    }
}

//MARK: - API
extension ICChatManager {
    private func apiHistory(channelID: String, completion: @escaping ([ICChatData]) -> ()) {
        chatAPIService
            .apiHistory(channelID: channelID, offset: 0, count: 100)
            .subscribe { (datas) in
                completion(datas)
            } onError: { (error) in
                
            }
            .disposed(by: disposeBag)
    }
}
