//
//  ICChannel.swift
//  Icebaby
//
//  Created by Henry.Liao on 2020/12/11.
//

import UIKit

class ICChannel: Codable {
    var id: String?
    var latestMsg: ICMessageData?
    var lastSeenSeq: Int?
    var status: Int?
    var type: Int?
    var unread: Int?
    var createAt: String?
    var closeAt: String?
    var girlOfflineAt: String?
    var me: ICMemberItem?
    var member: ICMemberItem?
    
    enum CodingKeys : String, CodingKey {
        case id = "id"
        case latestMsg = "latest_msg"
        case lastSeenSeq = "last_seen_seq"
        case status = "status"
        case type = "type"
        case unread = "unread"
        case createAt = "create_at"
        case closeAt = "close_at"
        case girlOfflineAt = "girl_offline_at"
        case me = "me"
        case member = "member"
    }
}
