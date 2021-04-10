//
//  ICChatData.swift
//  Icebaby
//
//  Created by Henry.Liao on 2020/12/15.
//

import UIKit

struct ICMessageData: Codable {
    var seq: Int = 0
    var type: String?
    var channelId: String?
    var payload: ICMsgPayload?
    
    enum CodingKeys : String, CodingKey {
        case type = "type"
        case channelId = "channel_id"
        case payload = "payload"
    }
}

struct ICMsgPayload: Codable {
    var id: String?
    var date: String?
    var uid: Int?
    var nickname: String?
    var msg: String?
}
