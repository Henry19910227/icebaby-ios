//
//  ICChatData.swift
//  Icebaby
//
//  Created by Henry.Liao on 2020/12/15.
//

import UIKit

struct ICChatData: Codable {
    var type: String?
    var channelId: String?
    var message: ICChatMsg?
    
    enum CodingKeys : String, CodingKey {
        case type = "type"
        case channelId = "channel_id"
        case message = "message"
    }
}

struct ICChatMsg: Codable {
    var id: String?
    var date: String?
    var uid: Int?
    var nickname: String?
    var msg: String?
}
