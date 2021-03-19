//
//  ICUserBrief.swift
//  Icebaby
//
//  Created by Henry.Liao on 2021/3/18.
//

import UIKit

class ICUserBrief: Codable {
    var id: Int?
    var role: Int?
    var isOnline: Int?
    var info: ICUserInfoBrief?
    enum CodingKeys : String, CodingKey {
        case id = "id"
        case role = "role"
        case isOnline = "is_online"
        case info = "info"
    }
}

class ICUserInfoBrief: Codable {
    var nickname: String?
    var avatar: String?
    var intro: String?
    var birthday: String?
    var area: String?
}
