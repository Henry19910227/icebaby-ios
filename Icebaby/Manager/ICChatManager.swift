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
}

extension ICChatManager {
    public func start() {
        let url = "ws://127.0.0.1:8000/connection/websocket?format=protobuf"
        client = CentrifugeClient(url: url, config: CentrifugeClientConfig(), delegate: self)
        client.setToken(token() ?? "")
    }
}

extension ICChatManager: CentrifugeClientDelegate {
    func onConnect(_ client: CentrifugeClient, _ event: CentrifugeConnectEvent) {
        
    }
    func onMessage(_ client: CentrifugeClient, _ event: CentrifugeMessageEvent) {
        
    }
}
