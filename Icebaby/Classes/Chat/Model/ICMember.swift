//
//  ICMember.swift
//  Icebaby
//
//  Created by Henry.Liao on 2020/12/11.
//

import UIKit

class ICMember: Codable {
    var userID: Int?
    var type: Int?
    var nickname: String?
    var avatar: String?
    var readAt: String?
    
    enum CodingKeys : String, CodingKey {
        case userID = "user_id"
        case type = "type"
        case nickname = "nickname"
        case avatar = "avatar"
        case readAt = "read_at"
    }
}
