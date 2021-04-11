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


struct ICChannelData {
    var channel: ICChannel?
    var isPullHistory = false
    var history: [ICMessageData] = []
    var sub: CentrifugeSubscription?
}

class ICChatManager: NSObject {
    static let shard = ICChatManager(userManager: ICUserManager(),
                                     chatAPIService: ICChatAPIService(userManager: ICUserManager()))
    private lazy var client: CentrifugeClient = {
        let url = "ws://127.0.0.1:8000/connection/websocket?format=protobuf"
//        let url = "ws://104.199.204.119:31500/connection/websocket?format=protobuf"
        let client = CentrifugeClient(url: url, config: CentrifugeClientConfig(), delegate: self)
        return client
    }()
    
    //DI
    private let userManager: UserManager
    private let chatAPIService: ICChatAPI
    
    //Tool
    private let dateFormatter = ICDateFormatter()
    
    //Data
    private var history:[String: [ICMessageData]] = [:]
    private var unreadMessage:[String: [ICMessageData]] = [:]
    private var readDateDict: [String: Date] = [:]
    private var channelDataPool: [String: ICChannelData] = [:]
    
    //Rx
    private let disposeBag = DisposeBag()
    
    //Input
    public let sendMessage = PublishSubject<(String, Data?)>()
    
    //Output
    public let updateLatestMsg = PublishSubject<ICMessageData?>()
    public let updateUnreadCount = PublishSubject<(String, Int)>()
    public let updateChannelStatus = PublishSubject<(String, Int)>()
    public let channels = ReplaySubject<[ICChannel]>.create(bufferSize: 1)
    
    
    public let subscribe = PublishSubject<String>()
    public let onSubscribeSuccess = PublishSubject<(String, [ICMessageData])>()
    public let onSubscribeError = PublishSubject<String>()
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
    // 連接聊天後台
    public func connect(token: String, uid: Int) {
        client.setToken(token)
        client.connect()
    }
    
    // 拉取我的頻道列表
    public func pullMyChannels() {
        apiGetMyChannels(userID: userManager.uid())
    }
    
    // 訂閱單個頻道
    public func subscribeChannel(_ channelID: String?) -> CentrifugeSubscription? {
        guard let channelID = channelID else { return nil }
        var subscribeItem: CentrifugeSubscription?
        do {
            subscribeItem = try client.newSubscription(channel: channelID, delegate: self)
        } catch {
            onSubscribeError.onNext(error.localizedDescription)
        }
        subscribeItem?.subscribe()
        return subscribeItem
    }
    
    // 獲取歷史訊息
    public func history(channelID: String, completion: @escaping ([ICMessageData]) -> Void) {
        if var channelData = channelDataPool[channelID] {
            if !channelData.isPullHistory {
                apiHistory(channelID: channelID) { (datas) in
                    channelData.history = datas
                }
            }
            completion(channelData.history)
        }
    }
}

//MARK: - Input Bind
extension ICChatManager {
    private func bindSendMessage(_ sendMessage: Driver<(String, Data?)>) {
        sendMessage
            .filter({ [unowned self] (channelID, data) -> Bool in
                return data != nil && self.channelDataPool[channelID] != nil
            })
            .map({ [unowned self] (channelID, data) -> (CentrifugeSubscription, Data) in
                return (self.channelDataPool[channelID]!.sub! , data!)
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
        print("連線成功!!!!!")
        pullMyChannels()
        _ = subscribeChannel(String(userManager.uid()))
    }
}

//MARK: - CentrifugeSubscriptionDelegate
extension ICChatManager: CentrifugeSubscriptionDelegate {
    func onPublish(_ sub: CentrifugeSubscription, _ event: CentrifugePublishEvent) {
        do {
            let data = try JSONDecoder().decode(ICMessageData.self, from: event.data)
            if data.type == "message" {
                //將新訊息存入歷史訊息中
                if var channelData = channelDataPool[data.channelId ?? ""] {
                    channelData.channel?.latestMsg = data.payload?.msg
                    channelData.channel?.unread = data.seq - (channelData.channel?.lastSeenSeq ?? 0)
                    channelData.history.append(data)
                    
                    updateLatestMsg.onNext(data)
                    updateUnreadCount.onNext((data.channelId ?? "", channelData.channel?.unread ?? 0))
                }
            }
            if data.type == "activate" {
                if let channelData = channelDataPool[data.channelId ?? ""] {
                    //頻道已存在:變更狀態並發出訊號更新UI
                    channelData.channel?.status = 1
                    updateChannelStatus.onNext((channelData.channel?.id ?? "", 1))
                } else {
                    //頻道不存在:獲取此頻道資訊放入pool, 並且發訊號更新整個列表
                    apiGetMyChannel(channelID: data.channelId ?? "")
                }
            }
        } catch {
            print("Error!")
        }
    }
    
    func onSubscribeSuccess(_ sub: CentrifugeSubscription, _ event: CentrifugeSubscribeSuccessEvent) {
        print("subscribe channel \(sub.channel)")
    }
    
    func onSubscribeError(_ sub: CentrifugeSubscription, _ event: CentrifugeSubscribeErrorEvent) {
        onSubscribeError.onNext("subscribe channel \(sub.channel) error")
    }
}

//MARK: - Other
extension ICChatManager {
    //從緩存中取得頻道列表
    public func getChannelsFromPool() -> [ICChannel] {
        var channels: [ICChannel] = []
        for (_, v) in channelDataPool {
            if let channel = v.channel {
                channels.append(channel)
            }
        }
        return channels
    }
}

//MARK: - API
extension ICChatManager {
    
    private func apiGetMyChannel(channelID: String) {
        chatAPIService
            .apiGetChannel(channelID: channelID)
            .do(onSuccess: { [unowned self] (channel) in
                if let channel = channel {
                    //訂閱頻道
                    if let sub = self.subscribeChannel(channel.id) {
                        //將channel資料加入pool
                        self.channelDataPool[channel.id ?? ""] = ICChannelData(channel: channel, sub: sub)
                    }
                }
            })
            .subscribe { [unowned self] (channel) in
                self.channels.onNext(self.getChannelsFromPool())
            } onError: { (error) in
                
            }
            .disposed(by: disposeBag)

    }
    
    private func apiGetMyChannels(userID: Int) {
        chatAPIService
            .apiGetChannels(userID: userManager.uid())
            .do(onSuccess: { [unowned self] (channels) in
                for channel in channels {
                    if let sub = self.subscribeChannel(channel.id) {
                        self.channelDataPool[channel.id ?? ""] = ICChannelData(channel: channel, sub: sub)
                    }
                }
            })
            .subscribe(onSuccess: { [unowned self] (channels) in
                self.channels.onNext(self.getChannelsFromPool())
            }, onError: { (error) in
                
            })
            .disposed(by: disposeBag)
    }
    
    private func apiHistory(channelID: String, completion: @escaping ([ICMessageData]) -> ()) {
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
