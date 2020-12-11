//
//  ICChannel.swift
//  Icebaby
//
//  Created by Henry.Liao on 2020/12/11.
//

import UIKit

class ICChannel: Codable {
    var id: Int?
    var status: Int?
    var members: [ICMember]?
    var type: Int?
}
