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
    private let channelID: String
    
    //Tool
    private let dateFormatter = ICDateFormatter()
    
    //RX
    private let disposeBag = DisposeBag()
    private let messageSubject = PublishSubject<[ICMessage]>()
    private var senderSubject = PublishSubject<SenderType>()
    
    //Status
    private var allowChat = false
    
    //Data
    private var messages: [ICMessage] = []
    
    
    struct Input {
        public let trigger: Driver<Void>
        public let sendMessage: Driver<String>
        public let allowChat: Driver<Bool>
    }
    
    struct Output {
        public let sender: Driver<SenderType>
        public let messages: Driver<[ICMessage]>
    }
    
    init(navigator: ICChatNavigator,
         chatAPIService: ICChatAPI,
         chatManager: ICChatManager,
         userManager: UserManager,
         channelID: String) {
        
        self.navigator = navigator
        self.chatAPIService = chatAPIService
        self.chatManager = chatManager
        self.userManager = userManager
        self.channelID = channelID
    }
    
}

//MARK: - Transform
extension ICChatViewModel {
    @discardableResult func transform(input: Input) -> Output {
        bindTrigger(input.trigger)
        bindAllowChat(input.allowChat)
        bindSendMessage(input.sendMessage)
        bindOnPublish(chatManager.onPublish)
        return Output(sender: senderSubject.asDriver(onErrorJustReturn: ICSender()),
                      messages: messageSubject.asDriver(onErrorJustReturn: []))
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
                self.getHistory()
            })
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
                self.chatManager.sendMessage.onNext((self.channelID, data))
            })
            .disposed(by: disposeBag)
    }
    
    private func bindOnPublish(_ onPublish: Observable<ICChatData?>) {
        onPublish
            .filter({ [unowned self] (_) -> Bool in
                return self.allowChat
            })
            .filter({ (data) -> Bool in
                return data?.type == "message"
            })
            .subscribe(onNext: { [unowned self] (data) in
                if self.channelID == data?.channelId ?? ""{
                    let message = ICMessage(data: data?.message ?? ICChatMsg())
                    self.messages.append(message)
                    self.messageSubject.onNext(self.messages)
                }
            })
            .disposed(by: disposeBag)
    }
}

//MARK: - Other
extension ICChatViewModel {
    private func getChatData(text: String) -> Data? {
        let date = dateFormatter.dateToDateString(Date(), "yyyy-MM-dd HH:mm:ss") ?? ""
        let msdId = "\(userManager.uid())-" + (dateFormatter.dateToDateString(Date(), "yyyyMMddHHmmss") ?? "")
        let msgDict: [String: Any] = ["id": msdId,
                                      "date": date,
                                      "uid": userManager.uid(),
                                      "nickname": userManager.nickname(),
                                      "msg": text]
        let dataDict: [String: Any] = ["type": "message",
                                       "channel_id": channelID,
                                       "message": msgDict]
        do {
            let data = try JSONSerialization.data(withJSONObject: dataDict, options: .prettyPrinted)
            return data
        } catch  {
            return nil
        }
    }
    
    private func getHistory() {
        chatManager.history(channelID: channelID) { [unowned self] (datas) in
            self.messages = datas.map { (data) -> ICMessage in
                return ICMessage(data: data.message)
            }
            self.messageSubject.onNext(self.messages)
        }
    }
}
