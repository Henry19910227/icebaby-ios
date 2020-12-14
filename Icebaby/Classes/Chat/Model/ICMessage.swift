//
//  ICMessage.swift
//  Icebaby
//
//  Created by Henry.Liao on 2020/12/14.
//

import UIKit
import MessageKit

class ICMessage: MessageType {
    var sender: SenderType = ICSender()
    var messageId: String = ""
    var sentDate: Date = Date()
    var kind: MessageKind = .text("")
}
