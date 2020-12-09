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

struct ICChatData: Codable {
    var channel: String?
    var type: String?
    var uid: Int?
    var content: String?
}

class ICChatManager: NSObject {
    static let shard = ICChatManager()
    private lazy var client: CentrifugeClient = {
        let url = "ws://127.0.0.1:8000/connection/websocket?format=protobuf"
        let client = CentrifugeClient(url: url, config: CentrifugeClientConfig(), delegate: self)
        return client
    }()
    private var uid: Int = 0
    private var currentSubscribe: [String: CentrifugeSubscription] = [:]
    
    //RX
    public let onPublish = PublishSubject<ICChatData?>()
    public let subscribe = PublishSubject<String>()
    public let onSubscribeSuccess = PublishSubject<String>()
}

//MARK: - Public
extension ICChatManager {
    public func connect(token: String, uid: Int) {
        client.setToken(token)
        client.connect()
        subscribeChannel(String(uid))
    }
}

extension ICChatManager: CentrifugeClientDelegate {
    func onConnect(_ client: CentrifugeClient, _ event: CentrifugeConnectEvent) {
    
    }
}

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
        onSubscribeSuccess.onNext(sub.channel)
    }
    
    func onSubscribeError(_ sub: CentrifugeSubscription, _ event: CentrifugeSubscribeErrorEvent) {
        print("Subscribe \(sub.channel) error" )
    }
}

//MARK: - Other
extension ICChatManager {
    public func subscribeChannel(_ channel: String?) {
        guard let channel = channel, currentSubscribe[channel] == nil else { return }
        var subscribeItem: CentrifugeSubscription?
        do {
            subscribeItem = try client.newSubscription(channel: channel, delegate: self)
        } catch {
            print("subscribe error!")
        }
        subscribeItem?.subscribe()
        currentSubscribe[channel] = subscribeItem
    }
}
