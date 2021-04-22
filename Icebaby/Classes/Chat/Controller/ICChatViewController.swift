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
    private let exit = PublishSubject<Void>()
    private let allowChat = PublishSubject<Bool>()
    private let sendMsg = PublishSubject<String>()

    // Data
    private var messages: [MessageType] = []
    private var sender: SenderType?
    
    // Tool
    private let dateFormatter = ICDateFormatter()

    // UI
    private lazy var statusBarButtonItem: UIBarButtonItem = {
        let statusButton = UIBarButtonItem()
        statusButton.title = "test"
        return statusButton
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
        trigger.onNext(())
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        exit.onNext(())
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
        let input = ICChatViewModel.Input(trigger: trigger.asDriver(onErrorJustReturn: ()),
                                          exit: exit.asDriver(onErrorJustReturn: ()),
                                          sendMessage: sendMsg.asDriver(onErrorJustReturn: ""),
                                          allowChat: allowChat.asDriver(onErrorJustReturn: false),
                                          changeStatus: statusBarButtonItem.rx.tap.asDriver())
        let output = viewModel?.transform(input: input)
        
        output?
            .sender
            .drive(onNext: { [unowned self] (sender) in
                self.sender = sender
            })
            .disposed(by: disposeBag)
        
        output?
            .messages
            .do(onNext: { [unowned self] (messages) in
                self.messages = messages
            })
            .drive(onNext: { [unowned self] (_) in
                self.messagesCollectionView.reloadData()
            })
            .disposed(by: disposeBag)
        
        output?
            .status
            .drive(onNext: { [unowned self] (isActivate) in
                self.statusBarButtonItem.title = isActivate ? "關閉頻道" : "開啟頻道"
                self.messagesCollectionView.backgroundColor = isActivate ? .white : .gray
            })
            .disposed(by: disposeBag)
        
        output?
            .enableChangeStatus
            .drive(statusBarButtonItem.rx.isEnabled)
            .disposed(by: disposeBag)
    }
}

//MARK: - UI
extension ICChatViewController {
    private func initUI() {
        messageInputBar.delegate = self
        setupMessageAvatar()
        setupMessageTopLabel()
        setupMessageBottomLabel()
        navigationItem.rightBarButtonItem = statusBarButtonItem
    }
    
    private func setupMessageAvatar() {
        messagesCollectionView.messagesCollectionViewFlowLayout.setMessageIncomingAvatarSize(CGSize(width: 0, height: 0))
        messagesCollectionView.messagesCollectionViewFlowLayout.setMessageIncomingAvatarPosition(AvatarPosition(vertical: .messageBottom))
        messagesCollectionView.messagesCollectionViewFlowLayout.setMessageOutgoingAvatarSize(CGSize(width: 0, height: 0))
        messagesCollectionView.messagesCollectionViewFlowLayout.setMessageOutgoingAvatarPosition(AvatarPosition(vertical: .messageBottom))
    }
    
    private func setupMessageTopLabel() {
        let incomingAlignment = LabelAlignment(textAlignment: .left, textInsets: UIEdgeInsets(top: 0, left: 15, bottom: 3, right: 0))
        let outgoingAlignment = LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 3, right: 15))
        messagesCollectionView.messagesCollectionViewFlowLayout.setMessageIncomingMessageTopLabelAlignment(incomingAlignment)
        messagesCollectionView.messagesCollectionViewFlowLayout.setMessageOutgoingMessageTopLabelAlignment(outgoingAlignment)
    }
    
    private func setupMessageBottomLabel() {
        let incomingAlignment = LabelAlignment(textAlignment: .left, textInsets: UIEdgeInsets(top: 3, left: 15, bottom: 0, right: 0))
        let outgoingAlignment = LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(top: 3, left: 0, bottom: 0, right: 15))
        messagesCollectionView.messagesCollectionViewFlowLayout.setMessageIncomingMessageBottomLabelAlignment(incomingAlignment)
        messagesCollectionView.messagesCollectionViewFlowLayout.setMessageOutgoingMessageBottomLabelAlignment(outgoingAlignment)
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
    
    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let timeStr = dateFormatter.dateToDateString(message.sentDate, "HH:mm") ?? ""
        return NSAttributedString(string: timeStr, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10)])
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
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 10
    }
}

//MARK: - InputBarAccessoryViewDelegate
extension ICChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        sendMsg.onNext(text)
        inputBar.inputTextView.text = ""
    }
}
