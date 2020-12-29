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
    private var unreadMessage:[String: [ICChatData]] = [:]
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
    public let historyError = PublishSubject<String>()
    
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
        //更新已讀時間
        readDateDict[channelID] = readDate
        
        //清除未讀訊息
        let lastReadDate = getMyLastReadDate(channelID: channelID)
        if unreadMessage[channelID] != nil {
            clearUnreadChatDatas(&unreadMessage[channelID]!, lastReadDate: lastReadDate)
        }
                
        //更新未讀數量
        unreadCount.onNext((channelID, unreadMessage[channelID]?.count ?? 0))
    }
    
    public func mychannels(onSuccess: @escaping ([ICChannel]) -> Void,
                           onError: @escaping (Error) -> Void) {
        chatAPIService
            .apiGetMyChannels()
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
                
                //將對方新訊息存到未讀區
                if data.message?.uid ?? 0 != userManager.uid() {
                    unreadMessage[data.channelId ?? ""]?.append(data)
                    unreadCount.onNext((sub.channel, unreadMessage[data.channelId ?? ""]?.count ?? 0))
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
            
            //加入自己的未讀訊息
            var myUnreadMsgs: [ICChatData] = []
            for data in datas {
                if self.userManager.uid() != data.message?.uid ?? 0 {
                    myUnreadMsgs.append(data)
                }
            }
            self.unreadMessage[sub.channel] = myUnreadMsgs
            
            //清除未讀訊息
            let lastReadDate = self.getMyLastReadDate(channelID: sub.channel)
            if unreadMessage[sub.channel] != nil {
                clearUnreadChatDatas(&unreadMessage[sub.channel]!, lastReadDate: lastReadDate)
            }
            //發送未讀數量訊號
            self.unreadCount.onNext((sub.channel, self.unreadMessage[sub.channel]?.count ?? 0))
            
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
            unreadCount.onNext((channel, unreadMessage[channel]?.count ?? 0))
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
    
    //清除未讀訊息
    private func clearUnreadChatDatas(_ chatDatas: inout [ICChatData], lastReadDate: Date?) {
        guard let lastReadDate = lastReadDate else { return }
        var messages = chatDatas
        for (index, msg) in messages.enumerated().reversed() {
            //判斷是來自對方的訊息
            if userManager.uid() != msg.message?.uid ?? 0 {
                let date = dateFormatter.dateStringToDate(msg.message?.date ?? "", "yyyy-MM-dd HH:mm:ss") ?? Date()
                //判斷訊息日期小於當前最後讀取日期，就將此訊息從未讀陣列中移除
                if dateFormatter.date(date, earlierThan: lastReadDate) {
                    messages.remove(at: index)
                }
            }
        }
        chatDatas = messages
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
            } onError: { [unowned self] (error) in
                guard let err = error as? ICError else { return }
                self.historyError.onNext("\(err.code ?? 0) \(err.msg ?? "")")
            }
            .disposed(by: disposeBag)
    }
}
