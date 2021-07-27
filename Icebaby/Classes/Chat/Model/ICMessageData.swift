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

struct ICActivateData: Codable {
    var seq: Int?
    var type: String?
    var channelID: String?
    var payload: ICChannel?
    
    enum CodingKeys : String, CodingKey {
        case seq = "seq"
        case type = "type"
        case channelID = "channel_id"
        case payload = "payload"
    }
}

struct ICOfflineUpdateData: Codable {
    var seq: Int?
    var type: String?
    var channelID: String?
    var payload: ICOfflineUpdatePayload?
    
    enum CodingKeys : String, CodingKey {
        case seq = "seq"
        case type = "type"
        case channelID = "channel_id"
        case payload = "payload"
    }
}

struct ICOfflineUpdatePayload: Codable {
    var offline: String?
    enum CodingKeys : String, CodingKey {
        case offline = "est_offline"
    }
}
