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
    private let trigger = PublishSubject<Void>()
    private let allowChat = PublishSubject<Bool>()
    private let sendMsg = PublishSubject<String>()

    // Data
    private var messages: [MessageType] = []
    private var sender: SenderType?

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
        trigger.onNext(())
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
        let input = ICChatViewModel.Input(trigger: trigger.asDriver(onErrorJustReturn: ()),
                                          sendMessage: sendMsg.asDriver(onErrorJustReturn: ""),
                                          allowChat: allowChat.asDriver(onErrorJustReturn: false))
        let output = viewModel?.transform(input: input)
        
        output?
            .sender
            .drive(onNext: { (sender) in
                self.sender = sender
            })
            .disposed(by: disposeBag)
        
        output?
            .messages
            .do(onNext: { [unowned self] (messages) in
                self.messages = messages
            })
            .drive(onNext: { [unowned self] (_) in
                self.reload()
            })
            .disposed(by: disposeBag)
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
        return sender ?? ICSender()
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

//MARK: -
extension ICChatViewController {
    func reload() {
        self.messagesCollectionView.performBatchUpdates {
            self.messagesCollectionView.insertSections([messages.count - 1])
        } completion: { (isFinish) in
            
        }
    }
}
