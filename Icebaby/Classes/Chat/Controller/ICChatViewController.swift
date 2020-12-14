//
//  ICChatViewController.swift
//  Icebaby
//
//  Created by 廖冠翰 on 2020/12/12.
//

import UIKit
import MessageKit

class ICChatViewController: MessagesViewController {

    private var messages: [MessageType] = {
        
        var messages: [MessageType] = []
        
        let sender1 = ICSender()
        sender1.displayName = "Henry"
        sender1.senderId = "10001"
        
        let sender2 = ICSender()
        sender2.displayName = "Jeff"
        sender2.senderId = "10002"
        
        let msg1 = ICMessage()
        msg1.messageId = "1"
        msg1.kind = .text("你好喔!!!")
        msg1.sentDate = Date()
        msg1.sender = sender1
        
        let msg2 = ICMessage()
        msg2.messageId = "2"
        msg2.kind = .text("HI~~~~~~~~~")
        msg2.sentDate = Date()
        msg2.sender = sender2
        
        messages.append(msg1)
        messages.append(msg2)
        return messages
    }()

}

//MARK: - Life Cycle
extension ICChatViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self

    }
}

extension ICChatViewController: MessagesDataSource {
    func currentSender() -> SenderType {
        let sender = ICSender()
        sender.displayName = "Henry"
        sender.senderId = "10001"
        return sender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let name = message.sender.displayName
        return NSAttributedString(string: name, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15)])
    }
    
}

extension ICChatViewController: MessagesDisplayDelegate {
    
}


extension ICChatViewController: MessagesLayoutDelegate {
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 20
    }
}

