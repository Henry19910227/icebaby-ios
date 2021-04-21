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
    var sub: CentrifugeSubscription?
}

class ICHistoryData {
    var needPull = true
    var messages: [ICMessageData]?
}

class ICChatManager: NSObject {
    static let shard = ICChatManager(userManager: ICUserManager(),
                                     chatAPIService: ICChatAPIService(userManager: ICUserManager()))
    private lazy var client: CentrifugeClient = {
        let url = "ws://127.0.0.1:8000/connection/websocket?format=protobuf"
//        let url = "ws://35.194.186.96:31500/connection/websocket?format=protobuf"
        let client = CentrifugeClient(url: url, config: CentrifugeClientConfig(), delegate: self)
        return client
    }()
    
    //DI
    private let userManager: UserManager
    private let chatAPIService: ICChatAPI
    
    //Tool
    private let dateFormatter = ICDateFormatter()
    
    //Data
    private var historyPool: [String: ICHistoryData] = [:]
    private var channelDataPool: [String: ICChannelData] = [:]
    
    //Rx
    private let disposeBag = DisposeBag()
    
    //Input
    public let sendMessage = PublishSubject<(String, Data?)>()
    
    //Output
    public let updateChannel = PublishSubject<ICChannel?>()
    public let addChannel = PublishSubject<ICChannel?>()
    public let updateHistory = PublishSubject<(String, [ICMessageData])>()
    public let channels = PublishSubject<[ICChannel]>()
    
    
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
    
    public func disconnect() {
        client.disconnect()
    }
    
    // 拉取我的頻道列表
    public func pullMyChannels() {
        apiGetMyChannels(userID: userManager.uid()) { [unowned self] (channels) in
            for channel in channels {
                //處理channel資訊
                if let channelData = channelDataPool[channel.id ?? ""] { //已存在channel
                    channelData.channel = channel
                } else { //未存在channel
                    let channelData = ICChannelData()
                    channelData.channel = channel
                    channelDataPool[channel.id ?? ""] = channelData
                }
                //處理channel訂閱
                if channel.status ?? 0 == 1 { //當頻道狀態為開啟時才訂閱
                    if let sub = subscribeChannel(channel.id) {
                        channelDataPool[channel.id ?? ""]?.sub = sub
                    }
                } else { //當頻道狀態為關閉時取消訂閱
                    channelDataPool[channel.id ?? ""]?.sub?.unsubscribe()
                }
            }
            //送出channel訊號
            self.channels.onNext(getChannelsFromPool())
        }
    }
    
    // 取得我的頻道列表
    public func getMyChannels() {
        channels.onNext(getChannelsFromPool())
    }
    
    // 拉取指定頻道歷史訊息
    public func pullHistory(channelID: String) {
        if let historyData = historyPool[channelID] {
            if historyData.needPull { //已登入過，但因為斷線原因，重新連接後需要追訊息
                apiHistory(channelID: channelID, startSeq: historyData.messages?.last?.seq, endSeq: nil, count: 100) { [unowned self] (msgs) in
                    for msg in msgs {
                        historyData.messages?.append(msg)
                    }
                    historyData.needPull = false
                    self.updateHistory.onNext((channelID, historyData.messages ?? []))
                }
                return
            }
            //發送歷史訊息更新信號
            self.updateHistory.onNext((channelID, historyData.messages ?? []))
            
        } else { //首次登入尚未拉取過訊息
            apiHistory(channelID: channelID, startSeq: nil, endSeq: nil, count: 100) { [unowned self] (msgs) in
                let historyData = ICHistoryData()
                historyData.messages = msgs
                self.historyPool[channelID] = historyData
                self.updateHistory.onNext((channelID, msgs))
            }
        }
    }
    
    // 以memberID獲取頻道
    public func getChannelWithFriend(_ friendID: Int) -> ICChannel? {
        for (_, v) in channelDataPool {
            if let channel = v.channel {
                if channel.member?.info?.userID ?? 0 == friendID {
                    return v.channel
                }
            }
        }
        return nil
    }
    
    // 更新最後讀取序列
    public func updateLastSeen(channelID: String) {
        if let channelData = channelDataPool[channelID] {
            channelData.channel?.unread = 0
            updateChannel.onNext(channelData.channel)
            //如果最後讀取序號有更新，再更新到server
            guard let latestSeq = channelData.channel?.latestMsg?.seq else { return }
            if latestSeq != (channelData.channel?.lastSeenSeq ?? 0) {
                channelData.channel?.lastSeenSeq = channelData.channel?.latestMsg?.seq ?? 0
                apiUpdateLastSeen(channelID: channelID, seq: channelData.channel?.latestMsg?.seq ?? 0)
            }
        }
    }
    
    //關閉頻道(停止收費)
    public func shutdownChannel(channelID: String) {
        apiShutdownChannel(channelID: channelID)
    }
    
    //開啟頻道
    public func activateChannel(channelID: String) {
        apiActivateChannel(channelID: channelID)
    }
    
    //創建並激活頻道
    public func createChannel(friendID: Int) {
        apiCreateChannel(friendID: friendID)
    }
}

//MARK: - Input Bind
extension ICChatManager {
    private func bindSendMessage(_ sendMessage: Driver<(String, Data?)>) {
        
        sendMessage
            .filter({ [unowned self] (channelID, data) -> Bool in
                return data != nil && self.channelDataPool[channelID]?.sub != nil
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
        print("連接聊天室成功 or 斷線重連成功")
        subscribeChannel(String(userManager.uid()))
        resetHistoryPoolStatus()
        pullMyChannels()
    }
    
    func onDisconnect(_ client: CentrifugeClient, _ event: CentrifugeDisconnectEvent) {
        print("與聊天室斷開連接: \(event.reason), reconnect: \(event.reconnect)")
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
                    historyPool[channelData.channel?.id ?? ""]?.messages?.append(msgData)
                    
                    //發布channel更新狀態
                    updateChannel.onNext(channelData.channel)
                    //發布history更新狀態
                    updateHistory.onNext((channelData.channel?.id ?? "", [msgData]))
                }
            }
            if msgData.type == "activate" {
                if let channelData = channelDataPool[msgData.channelID ?? ""] {
                    //頻道已存在:變更狀態並發出訊號更新UI 訂閱頻道
                    if let sub = self.subscribeChannel(channelData.channel?.id ?? "") {
                        channelData.channel?.status = 1
                        channelData.sub = sub
                    }
                    //發出訊號
                    updateChannel.onNext(channelData.channel)
                } else {
                    //頻道不存在:獲取此頻道資訊放入pool, 並且發訊號通知添加channel
                    apiGetMyChannel(channelID: msgData.channelID ?? "") { [unowned self] (channel) in
                        if let channel = channel {
                            //將channel資料加入pool
                            let channelData = ICChannelData()
                            channelData.channel = channel
                            self.channelDataPool[channel.id ?? ""] = channelData
                            //訂閱頻道
                            if let sub = self.subscribeChannel(channel.id) {
                                channelData.sub = sub
                            }
                        }
                        //發出訊號
                        self.addChannel.onNext(channel)
                    }
                }
            }
            if msgData.type == "shutdown" {
                //頻道已存在
                if let channelData = channelDataPool[msgData.channelID ?? ""] {
                    //退訂此頻道
                    channelData.sub?.unsubscribe()
                    channelData.sub = nil
                    channelData.channel?.status = 0
                    //發出訊號
                    updateChannel.onNext(channelData.channel)
                }
            }
        } catch {
            print("Error!")
        }
    }
    
    func onMessage(_ client: CentrifugeClient, _ event: CentrifugeMessageEvent) {
        print("onMessage :\(event.data)")
    }
    
    
    func onSubscribeSuccess(_ sub: CentrifugeSubscription, _ event: CentrifugeSubscribeSuccessEvent) {
        print("subscribe channel: \(sub.channel) recovered: \(event.recovered)")
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
    // 訂閱單個頻道
    @discardableResult private func subscribeChannel(_ channelID: String?) -> CentrifugeSubscription? {
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
    
    private func resetHistoryPoolStatus() {
        for (_, historyData) in historyPool {
            historyData.needPull = true
        }
    }
}

//MARK: - API
extension ICChatManager {
    
    private func apiGetMyChannel(channelID: String, success: @escaping (ICChannel?) -> ()) {
        chatAPIService
            .apiGetChannel(channelID: channelID)
            .subscribe { (channel) in
                success(channel)
            } onError: { (error) in
                guard let err = error as? ICError else { return }
                self.historyError.onNext("\(err.code ?? 0) \(err.msg ?? "")")
            }
            .disposed(by: disposeBag)

    }
    
    private func apiGetMyChannels(userID: Int, success: @escaping ([ICChannel]) -> ()) {
        chatAPIService
            .apiGetChannels(userID: userManager.uid())
            .subscribe(onSuccess: { (channels) in
                success(channels)
            }, onError: { (error) in
                guard let err = error as? ICError else { return }
                self.historyError.onNext("\(err.code ?? 0) \(err.msg ?? "")")
            })
            .disposed(by: disposeBag)
    }
    
    private func apiHistory(channelID: String, startSeq: Int?, endSeq: Int?, count: Int?, success: @escaping ([ICMessageData]) -> ()) {
        //尚未拉取過歷史訊息
        chatAPIService
            .apiHistory(channelID: channelID, startSeq: startSeq, endSeq: endSeq, count: count)
            .subscribe { (datas) in
                success(datas)
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
            } onError: { [unowned self] (error) in
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
            } onError: { [unowned self] (error) in
                guard let err = error as? ICError else { return }
                self.historyError.onNext("\(err.code ?? 0) \(err.msg ?? "")")
            }
            .disposed(by: disposeBag)
    }
    
    private func apiActivateChannel(channelID: String) {
        chatAPIService
            .apiActivateChannel(channelID: channelID)
            .subscribe { (channelID) in
                print("激活 \(channelID ?? "") 頻道!")
            } onError: { [unowned self] (error) in
                guard let err = error as? ICError else { return }
                self.historyError.onNext("\(err.code ?? 0) \(err.msg ?? "")")
            }
            .disposed(by: disposeBag)
    }
    
    private func apiCreateChannel(friendID: Int) {
        chatAPIService
            .apiCreateChannel(friendID: friendID)
            .subscribe { [unowned self] (channelID) in
                self.activateChannel(channelID: channelID ?? "")
                print("創建 \(channelID ?? "") 頻道!")
            } onError: { [unowned self] (error) in
                guard let err = error as? ICError else { return }
                self.historyError.onNext("\(err.code ?? 0) \(err.msg ?? "")")
            }
            .disposed(by: disposeBag)
    }
}
