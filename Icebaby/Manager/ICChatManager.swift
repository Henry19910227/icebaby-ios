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


struct ICChannelObject {
    var item: ICChannel?
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
    private var history:[String: [ICChatData]] = [:]
    private var unreadMessage:[String: [ICChatData]] = [:]
    private var readDateDict: [String: Date] = [:]
    private var channels: [ICChannel] = []
    private var channelMap: [String: ICChannelObject] = [:]
    
    //Rx
    private let disposeBag = DisposeBag()
    
    //Input
    public let sendMessage = PublishSubject<(String, Data?)>()
    
    //Output
    public let onPublish = PublishSubject<ICChatData?>()
    public let channelsSubject = ReplaySubject<[ICChannel]>.create(bufferSize: 1)
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
                return data != nil && self.channelMap[channelID] != nil
            })
            .map({ [unowned self] (channelID, data) -> (CentrifugeSubscription, Data) in
                return (self.channelMap[channelID]!.sub! , data!)
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
            if data.type == "activate" {
                if let channel = channelMap[data.channelId ?? ""] { //頻道已存在
                    channel.item?.status = 1
                    channelsSubject.onNext(getChannelsFromMap())
                } else { //頻道不存在
                    apiGetMyChannel(channelID: data.channelId ?? "")
                }
            }
            onPublish.onNext(data)
        } catch {
            print("Error!")
        }
    }
    
    func onSubscribeSuccess(_ sub: CentrifugeSubscription, _ event: CentrifugeSubscribeSuccessEvent) {
        print("subscribe channel \(sub.channel)")
        var channel = channelMap[sub.channel]
        if channel != nil {
            channel?.sub = sub
        }
    }
    
    func onSubscribeError(_ sub: CentrifugeSubscription, _ event: CentrifugeSubscribeErrorEvent) {
        onSubscribeError.onNext("subscribe channel \(sub.channel) error")
    }
}

//MARK: - Other
extension ICChatManager {
    //從緩存中取得頻道列表
    public func getChannelsFromMap() -> [ICChannel] {
        var channels: [ICChannel] = []
        for (_, v) in channelMap {
            if let channel = v.item {
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
            .do(onSuccess: { (channel) in
                if let channel = channel {
                    if let sub = self.subscribeChannel(channel.id) {
                        self.channelMap[channel.id ?? ""] = ICChannelObject(item: channel, sub: sub)
                    }
                }
            })
            .subscribe { [unowned self] (channel) in
                self.channelsSubject.onNext(self.getChannelsFromMap())
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
                        self.channelMap[channel.id ?? ""] = ICChannelObject(item: channel, sub: sub)
                    }
                }
            })
            .subscribe(onSuccess: { [unowned self] (channels) in
                self.channelsSubject.onNext(self.getChannelsFromMap())
            }, onError: { (error) in
                
            })
            .disposed(by: disposeBag)
    }
    
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
