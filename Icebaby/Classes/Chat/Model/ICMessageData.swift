//
//  ICChatData.swift
//  Icebaby
//
//  Created by Henry.Liao on 2020/12/15.
//

import UIKit

struct ICMessageData: Codable {
    var seq: Int?
    var type: String?
    var channelID: String?
    var payload: ICMsgPayload?
    
    enum CodingKeys : String, CodingKey {
        case seq = "seq"
        case type = "type"
        case channelID = "channel_id"
        case payload = "payload"
    }
}

struct ICMsgPayload: Codable {
    var id: String?
    var date: String?
    var uid: Int?
    var nickname: String?
    var body: String?
}
