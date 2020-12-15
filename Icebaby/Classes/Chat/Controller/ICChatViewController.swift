//
//  ICChatViewController.swift
//  Icebaby
//
//  Created by 廖冠翰 on 2020/12/12.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import RxCocoa
import RxSwift

class ICChatViewController: MessagesViewController {
    
    // Public
    public var viewModel: ICChatViewModel?
    
    // Rx
    private let disposeBag = DisposeBag()
    private let allowChat = PublishSubject<Bool>()
    private let sendMsg = PublishSubject<String>()

    private var messages: [MessageType] = {
        
        var messages: [MessageType] = []
        
        let sender1 = ICSender(senderId: "10001", displayName: "Henry")
        
        let sender2 = ICSender(senderId: "10002", displayName: "Jeff")
        
        let msg1 = ICMessage(data: nil)
        msg1.messageId = "1"
        msg1.kind = .text("你好喔!!!")
        msg1.sentDate = Date()
        msg1.sender = sender1
        
        let msg2 = ICMessage(data: nil)
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
        initUI()
        bindViewModel()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        allowChat.onNext(true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        allowChat.onNext(false)
    }
}

//MARK: - Bind
extension ICChatViewController {
    private func bindViewModel() {
        let input = ICChatViewModel.Input(sendMessage: sendMsg.asDriver(onErrorJustReturn: ""),
                                          allowChat: allowChat.asDriver(onErrorJustReturn: false))
        viewModel?.transform(input: input)
    }
}

//MARK: - UI
extension ICChatViewController {
    private func initUI() {
        messageInputBar.delegate = self
        setupMessageAvatar()
        setupMessageTopLabel()
    }
    
    private func setupMessageAvatar() {
        messagesCollectionView.messagesCollectionViewFlowLayout.setMessageIncomingAvatarSize(CGSize(width: 40, height: 40))
        messagesCollectionView.messagesCollectionViewFlowLayout.setMessageIncomingAvatarPosition(AvatarPosition(vertical: .messageBottom))
        messagesCollectionView.messagesCollectionViewFlowLayout.setMessageOutgoingAvatarSize(CGSize(width: 40, height: 40))
        messagesCollectionView.messagesCollectionViewFlowLayout.setMessageOutgoingAvatarPosition(AvatarPosition(vertical: .messageBottom))
    }
    
    private func setupMessageTopLabel() {
        let incomingAlignment = LabelAlignment(textAlignment: .left, textInsets: UIEdgeInsets(top: 0, left: 50, bottom: 0, right: 0))
        messagesCollectionView.messagesCollectionViewFlowLayout.setMessageIncomingMessageTopLabelAlignment(incomingAlignment)
        let outgoingAlignment = LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 50))
        messagesCollectionView.messagesCollectionViewFlowLayout.setMessageOutgoingMessageTopLabelAlignment(outgoingAlignment)
    }
}

extension ICChatViewController: MessagesDataSource {
    func currentSender() -> SenderType {
        return ICSender(senderId: "10001", displayName: "Henry")
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

//MARK: - MessagesDisplayDelegate
extension ICChatViewController: MessagesDisplayDelegate {
    
}

//MARK: - MessagesLayoutDelegate
extension ICChatViewController: MessagesLayoutDelegate {
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 20
    }
}

//MARK: - InputBarAccessoryViewDelegate
extension ICChatViewController: InputBarAccessoryViewDelegate {

    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        sendMsg.onNext(text)
    }
}

