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
    static let shard = ICChatManager()
    private lazy var client: CentrifugeClient = {
        let url = "ws://127.0.0.1:8000/connection/websocket?format=protobuf"
        let client = CentrifugeClient(url: url, config: CentrifugeClientConfig(), delegate: self)
        return client
    }()
    private var currentSubscribe: [String: CentrifugeSubscription] = [:]
    
    //Rx
    private let disposeBag = DisposeBag()
    
    //Input
    public let sendMessage = PublishSubject<(String, Data?)>()
    
    //Output
    public let onPublish = PublishSubject<ICChatData?>()
    public let subscribe = PublishSubject<String>()
    public let onSubscribeSuccess = PublishSubject<String>()
    public let onSubscribeError = PublishSubject<String>()
    
    override init() {
        super.init()
        bindSendMessage(sendMessage.asDriver(onErrorJustReturn: ("", nil)))
    }
}

//MARK: - Public
extension ICChatManager {
    public func connect(token: String, uid: Int) {
        client.setToken(token)
        client.connect()
        subscribeChannel(String(uid))
    }
    
    public func history(channelID: String, completion: @escaping ([ICChatData]) -> Void) {
        let sub = currentSubscribe[channelID]
        sub?.history(completion: { (pubs, error) in
            guard let pubs = pubs else {
                return
            }
            let chatDatas = pubs.map { (pub) -> ICChatData in
                let json = try! JSON(data: pub.data)
                return ICChatData()
            }
            completion([ICChatData]())
        })
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
                    guard let error = error else {
                        return
                    }
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
            onPublish.onNext(data)
        } catch {
            print("Error!")
        }
    }
    
    func onSubscribeSuccess(_ sub: CentrifugeSubscription, _ event: CentrifugeSubscribeSuccessEvent) {
        print("subscribe channel : \(sub.channel) success")
        currentSubscribe[sub.channel] = sub
        onSubscribeSuccess.onNext(sub.channel)
        
//        sub.history { (pubs, error) in
//            pubs?.first.
//        }
    }
    
    func onSubscribeError(_ sub: CentrifugeSubscription, _ event: CentrifugeSubscribeErrorEvent) {
        onSubscribeError.onNext("Subscribe \(sub.channel) error")
    }
}

//MARK: - Other
extension ICChatManager {
    public func subscribeChannel(_ channel: String?) {
        guard let channel = channel else { return }
        //已訂閱此channel
        if currentSubscribe[channel] != nil {
            print("\(channel) 已訂閱!")
            onSubscribeSuccess.onNext(channel)
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
