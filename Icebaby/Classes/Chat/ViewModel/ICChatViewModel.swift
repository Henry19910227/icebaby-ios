//
//  ICChatViewModel.swift
//  Icebaby
//
//  Created by Henry.Liao on 2020/12/15.
//

import UIKit
import RxCocoa
import RxSwift
import MessageKit

class ICChatViewModel: ICViewModel {
    
    //Dependency Injection
    private let navigator: ICChatNavigator
    private let chatAPIService: ICChatAPI
    private let chatManager: ICChatManager
    private let userManager: UserManager
    private var channel: ICChannel
    
    //Tool
    private let dateFormatter = ICDateFormatter()
    
    //RX
    private let disposeBag = DisposeBag()
    
    //Subject
    private let messageSubject = PublishSubject<[ICMessage]>()
    private var senderSubject = PublishSubject<SenderType>()
    private let showErrorMsgSubject = PublishSubject<String>()
    private let statusSubject = ReplaySubject<Bool>.create(bufferSize: 1)
    private let enableChangeStatusSubject = ReplaySubject<Bool>.create(bufferSize: 1)
    private let showLoadingSubject = PublishSubject<Bool>()
    
    //Status
    private var allowChat = false
    
    //Data
    private var messages: [ICMessage] = []
    
    
    struct Input {
        public let trigger: Driver<Void>
        public let exit: Driver<Void>
        public let sendMessage: Driver<String>
        public let allowChat: Driver<Bool>
        public let changeStatus: Driver<Void>
    }
    
    struct Output {
        public let sender: Driver<SenderType>
        public let messages: Driver<[ICMessage]>
        public let showErrorMsg: Driver<String>
        public let status: Driver<Bool>
        public let enableChangeStatus: Driver<Bool>
        public let showLoading: Driver<Bool>
    }
    
    init(navigator: ICChatNavigator,
         chatAPIService: ICChatAPI,
         chatManager: ICChatManager,
         userManager: UserManager,
         channel: ICChannel) {
        
        self.navigator = navigator
        self.chatAPIService = chatAPIService
        self.chatManager = chatManager
        self.userManager = userManager
        self.channel = channel
        setupChannel(channel)
        bindOnShutdown(chatManager.onShutdown.asDriver(onErrorJustReturn: ""))
        bindOnActivate(chatManager.onActivate.asDriver(onErrorJustReturn: nil))
        bindUpdateHistory(chatManager.updateHistory.asDriver(onErrorJustReturn: ("", [])))
        bindConnectSuccess(chatManager.connectSuccess.asDriver(onErrorJustReturn: ()))
        bindPublishing(chatManager.publishing.asDriver(onErrorJustReturn: ""))
        bindPublishError(chatManager.publishError.asDriver(onErrorJustReturn: ("", "")))
        bindPublishSuccess(chatManager.publishSuccess.asDriver(onErrorJustReturn: ""))
    }
}

//MARK: - Transform
extension ICChatViewModel {
    @discardableResult func transform(input: Input) -> Output {
        bindTrigger(input.trigger)
        bindExit(input.exit)
        bindAllowChat(input.allowChat)
        bindSendMessage(input.sendMessage)
        bindStatusChange(input.changeStatus)
        return Output(sender: senderSubject.asDriver(onErrorJustReturn: ICSender()),
                      messages: messageSubject.asDriver(onErrorJustReturn: []),
                      showErrorMsg: showErrorMsgSubject.asDriver(onErrorJustReturn: ""),
                      status: statusSubject.asDriver(onErrorJustReturn: false),
                      enableChangeStatus: enableChangeStatusSubject.asDriver(onErrorJustReturn: false),
                      showLoading: showLoadingSubject.asDriver(onErrorJustReturn: false))
    }
}

//MARK: - Bind
extension ICChatViewModel {
    
    private func bindTrigger(_ trigger: Driver<Void>) {
        trigger
            .do(onNext: { [unowned self] (_) in
                self.senderSubject.onNext(ICSender(senderId: "\(self.userManager.uid())",
                                                   displayName: self.userManager.nickname()))
            })
            .drive(onNext: { [unowned self] (_) in
                self.chatManager.pullHistory(channelID: self.channel.id ?? "")
                self.chatManager.updateLastSeen(channelID: self.channel.id ?? "")
            })
            .disposed(by: disposeBag)
    }
    
    private func setupChannel(_ channel: ICChannel) {
        statusSubject.onNext(channel.status ?? 0 == 1)
        enableChangeStatusSubject.onNext(channel.me?.type ?? 0 == 1) //type = 1(房主) 才能操作開啟 or 關閉頻道
    }
    
    private func bindConnectSuccess(_ connectSuccess: Driver<Void>) {
        connectSuccess
            .do { [unowned self] (_) in
                self.messages.removeAll() //斷線重連後必須先清空紀錄
                self.chatManager.pullHistory(channelID: self.channel.id ?? "")
            }
            .drive()
            .disposed(by: disposeBag)

    }
    
    private func bindOnShutdown(_ onShutdown: Driver<String>) {
        onShutdown
            .filter({ [unowned self] (channelID) -> Bool in
                return self.channel.id ?? "" == channelID
            })
            .drive { [unowned self] (channelID) in
                self.statusSubject.onNext(false)
            }
            .disposed(by: disposeBag)

    }
    
    private func bindOnActivate(_ onActivate: Driver<ICChannel?>) {
        onActivate
            .filter({ [unowned self] (channel) -> Bool in
                guard let channelID = channel?.id else { return false }
                return self.channel.id ?? "" == channelID
            })
            .drive { [unowned self] (channelID) in
                self.statusSubject.onNext(true)
            }
            .disposed(by: disposeBag)
    }
    
    private func bindStatusChange(_ statusChange: Driver<Void>) {
        statusChange
            .drive(onNext: { [unowned self] (_) in
                if self.channel.status ?? 0 == 1 {
                    print("關閉頻道")
                    self.chatManager.shutdownChannel(channelID: self.channel.id ?? "")
                } else {
                    print("開啟頻道")
                    self.chatManager.activateChannel(channelID: self.channel.id ?? "")
                }
                
            })
            .disposed(by: disposeBag)
    }
    
    private func bindExit(_ exit: Driver<Void>) {
        exit
            .do(onNext: { [unowned self] (_) in
                self.chatManager.updateLastSeen(channelID: self.channel.id ?? "")
            })
            .drive()
            .disposed(by: disposeBag)
    }
    
    private func bindAllowChat(_ allowChat: Driver<Bool>) {
        allowChat
            .do(onNext: { [unowned self] (isAllow) in
                self.allowChat = isAllow
            })
            .drive()
            .disposed(by: disposeBag)
    }
    
    private func bindSendMessage(_ sendMessage: Driver<String>) {
        sendMessage
            .map({ [unowned self] (text) -> Data? in
                return self.getChatData(text: text)
            })
            .filter({ (data) -> Bool in
                return data != nil
            })
            .drive(onNext: { [unowned self] (data) in
                self.chatManager.sendMessage.onNext((self.channel.id ?? "", data))
            })
            .disposed(by: disposeBag)
    }
    
    private func bindPublishing(_ publishing: Driver<String>) {
        publishing
            .filter { [unowned self] (channelID) -> Bool in
                return self.channel.id == channelID
            }
            .drive { [unowned self] (_) in
                self.showLoadingSubject.onNext(true)
            }
            .disposed(by: disposeBag)
    }
    
    private func bindPublishError(_ publishError: Driver<(String, String)>) {
        publishError
            .filter { [unowned self] (channelID, _) -> Bool in
                return self.channel.id == channelID
            }
            .drive { [unowned self] (_, msg) in
                self.showLoadingSubject.onNext(false)
                self.showErrorMsgSubject.onNext(msg)
            }
            .disposed(by: disposeBag)
    }
    
    private func bindPublishSuccess(_ publishSuccess: Driver<String>) {
        publishSuccess
            .filter { [unowned self] (channelID) -> Bool in
                return self.channel.id == channelID
            }
            .drive { [unowned self] (_) in
                self.showLoadingSubject.onNext(false)
            }
            .disposed(by: disposeBag)
    }
    
    private func bindUpdateHistory(_ updateHistory: Driver<(String, [ICMessageData])>) {
        updateHistory
            .filter ({ [unowned self] (channelID, msgDatas) -> Bool in
                return self.channel.id ?? "" == channelID
            })
            .map({ (channelID, msgDatas) -> [ICMessage] in
                return msgDatas.map { (msgData) -> ICMessage in
                    return ICMessage(data: msgData.payload)
                }
            })
            .do { [unowned self] (msgs) in
                for msg in msgs {
                    self.messages.append(msg)
                }
                self.messageSubject.onNext(self.messages)
            }
            .drive()
            .disposed(by: disposeBag)
    }
}

//MARK: - Other
extension ICChatViewModel {
    private func getChatData(text: String) -> Data? {
        let date = dateFormatter.dateToDateString(Date(), "yyyy-MM-dd HH:mm:ss") ?? ""
        let msdId = "\(userManager.uid())-" + (dateFormatter.dateToDateString(Date(), "yyyyMMddHHmmss") ?? "")
        let payload: [String: Any] = ["id": msdId,
                                      "date": date,
                                      "uid": userManager.uid(),
                                      "nickname": userManager.nickname(),
                                      "body": text]
        
        let message: [String: Any] = ["type": "message",
                                      "channel_id": self.channel.id ?? "",
                                      "payload": payload]
        do {
            let data = try JSONSerialization.data(withJSONObject: message, options: .prettyPrinted)
            return data
        } catch  {
            return nil
        }
    }
}
