//
//  ICChatManager.swift
//  Icebaby
//
//  Created by 廖冠翰 on 2020/12/8.
//

import UIKit
import SwiftCentrifuge

class ICChatManager: NSObject, APIToken {
    static let shard = ICChatManager()
    private lazy var client: CentrifugeClient = {
        let url = "ws://127.0.0.1:8000/connection/websocket?format=protobuf"
        let client = CentrifugeClient(url: url, config: CentrifugeClientConfig(), delegate: self)
        return client
    }()
    
    private var userSub: CentrifugeSubscription?
}

extension ICChatManager {
    public func start(token: String) {
        client.setToken(token)
        client.connect()
        do {
            userSub = try client.newSubscription(channel: "chat", delegate: self)
        } catch {
            print("subscribe error!")
        }
        userSub?.subscribe()
    }
}

extension ICChatManager: CentrifugeClientDelegate {
    func onConnect(_ client: CentrifugeClient, _ event: CentrifugeConnectEvent) {
    
    }
}

extension ICChatManager: CentrifugeSubscriptionDelegate {
    func onPublish(_ sub: CentrifugeSubscription, _ event: CentrifugePublishEvent) {
        print("\(sub.channel) \(String(data: event.data, encoding: .utf8) ?? "")")
    }
    
    func onSubscribeSuccess(_ sub: CentrifugeSubscription, _ event: CentrifugeSubscribeSuccessEvent) {
        print("Subscribe \(sub.channel) success" )
    }
    
    func onSubscribeError(_ sub: CentrifugeSubscription, _ event: CentrifugeSubscribeErrorEvent) {
        print("Subscribe \(sub.channel) error" )
    }
}
