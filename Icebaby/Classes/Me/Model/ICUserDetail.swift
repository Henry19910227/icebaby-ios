//
//  ICUserDetail.swift
//  Icebaby
//
//  Created by 廖冠翰 on 2020/12/3.
//

import UIKit

class ICUserDetail: Codable {
    var id: Int?
    var role: Int?
    var info: ICUserInfoDetail?
}

class ICUserInfoDetail: Codable {
    var idCard: String?
    var nickname: String?
    var avatar: String?
    var intro: String?
    var sex: String?
    var birthday: String?
    var email: String?
    var area: String?
    var height: Int?
    var weight: Int?
    var favorite: String?
    var smoke: Int?
    var dring: Int?
    var inviteCode: String?
    var estOffline: String?
    
    enum CodingKeys : String, CodingKey {
        case idCard = "id_card"
        case nickname = "nickname"
        case avatar = "avatar"
        case intro = "intro"
        case sex = "sex"
        case birthday = "birthday"
        case email = "email"
        case area  = "area"
        case height  = "height"
        case weight = "weight"
        case favorite = "favorite"
        case smoke = "smoke"
        case dring = "dring"
        case inviteCode = "invite_code"
        case estOffline = "est_offline"
    }
}
