//
//  ICChannel.swift
//  Icebaby
//
//  Created by Henry.Liao on 2020/12/11.
//

import UIKit

class ICChannel: Codable {
    var id: String?
    var status: Int?
    var members: [ICMember]?
    var type: Int?
}

class ICChannelListItem: Codable {
    var id: String?
    var latestMsg: String?
    var status: Int?
    var type: Int?
    var unread: Int?
    var member: ICMemberItem?
    
    enum CodingKeys : String, CodingKey {
        case id = "id"
        case latestMsg = "latest_msg"
        case status = "status"
        case type = "type"
        case unread = "unread"
        case member = "member"
    }
}
