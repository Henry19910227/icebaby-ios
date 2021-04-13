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


class ICChannelData {
    var channel: ICChannel?
    var history: [ICMessageData]?
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
    public let updateChannel = PublishSubject<ICChannel?>()
    public let updateHistory = PublishSubject<(String, [ICMessageData])>()
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
    
    // 拉取指定頻道歷史訊息
    public func pullHistory(channelID: String) {
        apiHistory(channelID: channelID)
    }
    
    // 更新最後讀取序列
    public func updateLastSeen(channelID: String) {
        if let channelData = channelDataPool[channelID] {
            channelData.channel?.unread = 0
            updateChannel.onNext(channelData.channel)
            //如果最後讀取序號有更新，再更新到server
            if (channelData.channel?.latestMsg?.seq ?? 0) != (channelData.channel?.lastSeenSeq ?? 0) {
                channelData.channel?.lastSeenSeq = channelData.channel?.latestMsg?.seq ?? 0
                apiUpdateLastSeen(channelID: channelID, seq: channelData.channel?.latestMsg?.seq ?? 0)
            }
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
            var msgData = try JSONDecoder().decode(ICMessageData.self, from: event.data)
            if msgData.type == "message" {
                //將新訊息存入歷史訊息中
                if let channelData = channelDataPool[msgData.channelID ?? ""] {
                    //自增訊息序列號
                    msgData.seq = (channelData.channel?.latestMsg?.seq ?? 0) + 1
                    
                    //手動更新channel
                    channelData.channel?.latestMsg = msgData
                    channelData.channel?.unread = (channelData.channel?.unread ?? 0) + 1
                    channelData.history?.append(msgData)
                    
                    //發布channel更新狀態
                    updateChannel.onNext(channelData.channel)
                    //發布history更新狀態
                    updateHistory.onNext((channelData.channel?.id ?? "", [msgData]))
                }
            }
            if msgData.type == "activate" {
                if let channelData = channelDataPool[msgData.channelID ?? ""] {
                    //頻道已存在:變更狀態並發出訊號更新UI
                    channelData.channel?.status = 1
                    //更新channel狀態
                    updateChannel.onNext(channelData.channel)
                } else {
                    //頻道不存在:獲取此頻道資訊放入pool, 並且發訊號更新整個列表
                    apiGetMyChannel(channelID: msgData.channelID ?? "")
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
                        let channelData = ICChannelData()
                        channelData.channel = channel
                        channelData.sub = sub
                        self.channelDataPool[channel.id ?? ""] = channelData
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
                        let channelData = ICChannelData()
                        channelData.channel = channel
                        channelData.sub = sub
                        self.channelDataPool[channel.id ?? ""] = channelData
                    }
                }
            })
            .subscribe(onSuccess: { [unowned self] (channels) in
                self.channels.onNext(self.getChannelsFromPool())
            }, onError: { (error) in
                
            })
            .disposed(by: disposeBag)
    }
    
    private func apiHistory(channelID: String) {
        guard let channelData = channelDataPool[channelID]  else { return }
        //已從server拉取過歷史訊息
        if let history = channelData.history {
            updateHistory.onNext((channelID, history))
            return
        }
        //尚未拉取過歷史訊息
        chatAPIService
            .apiHistory(channelID: channelID, offset: 0, count: 100)
            .subscribe { [unowned self] (datas) in
                channelData.history = datas
                self.updateHistory.onNext((channelID, datas))
            } onError: { [unowned self] (error) in
                guard let err = error as? ICError else { return }
                self.historyError.onNext("\(err.code ?? 0) \(err.msg ?? "")")
            }
            .disposed(by: disposeBag)
    }
    
    private func apiUpdateLastSeen(channelID: String, seq: Int) {
        chatAPIService
            .apiUpdateLastSeen(channelID: channelID, seq: seq)
            .subscribe { (_) in
                print("更新了最後閱讀序號")
            } onError: { (error) in
                guard let err = error as? ICError else { return }
                self.historyError.onNext("\(err.code ?? 0) \(err.msg ?? "")")
            }
            .disposed(by: disposeBag)

    }
    
    private func apiShutdownChannel(channelID: String) {
        chatAPIService
            .apiShutdownChannel(channelID: channelID)
            .subscribe { (channelID) in
                print("關閉 \(channelID ?? "") 頻道!")
            } onError: { (error) in
                guard let err = error as? ICError else { return }
                self.historyError.onNext("\(err.code ?? 0) \(err.msg ?? "")")
            }
            .disposed(by: disposeBag)

    }
}
