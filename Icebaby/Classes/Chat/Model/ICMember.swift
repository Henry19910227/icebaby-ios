//
//  ICMember.swift
//  Icebaby
//
//  Created by Henry.Liao on 2020/12/11.
//

import UIKit

class ICMember: Codable {
    var type: Int?
    var readAt: String?
    var info: ICMemberInfo?
    
    enum CodingKeys : String, CodingKey {
        case type = "type"
        case readAt = "read_at"
        case info = "info"
    }
}

class ICMemberInfo: Codable {
    var userID: Int?
    var nickname: String?
    var avatar: String?
    
    enum CodingKeys : String, CodingKey {
        case userID = "user_id"
        case nickname = "nickname"
        case avatar = "avatar"
    }
}


class ICMemberItem: Codable {
    var id: Int?
    var type: Int?
    var info: ICMemberInfo?
}
