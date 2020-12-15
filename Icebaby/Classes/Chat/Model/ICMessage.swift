//
//  ICMessage.swift
//  Icebaby
//
//  Created by Henry.Liao on 2020/12/14.
//

import UIKit
import MessageKit

class ICMessage: MessageType {
    var messageId: String = ""
    var sender: SenderType = ICSender()
    var sentDate: Date = Date()
    var kind: MessageKind = .text("")
    
    init(data: ICChatMsg?) {
        messageId = data?.id ?? ""
        sender = ICSender(senderId: String(data?.uid ?? 0), displayName: data?.nickname ?? "")
        sentDate = Date()
        kind = .text(data?.msg ?? "")
    }
}
