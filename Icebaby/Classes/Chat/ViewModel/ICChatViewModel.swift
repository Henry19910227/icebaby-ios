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
    
    //Subject
    private let messageSubject = PublishSubject<[ICMessage]>()
    private var senderSubject = PublishSubject<SenderType>()
    private let showErrorMsgSubject = PublishSubject<String>()
    
    //Status
    private var allowChat = false
    
    //Data
    private var messages: [ICMessage] = []
    
    
    struct Input {
        public let trigger: Driver<Void>
        public let exit: Driver<Void>
        public let sendMessage: Driver<String>
        public let allowChat: Driver<Bool>
    }
    
    struct Output {
        public let sender: Driver<SenderType>
        public let messages: Driver<[ICMessage]>
        public let showErrorMsg: Driver<String>
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
        bindExit(input.exit)
        bindAllowChat(input.allowChat)
        bindUpdateHistory(chatManager.updateHistory.asDriver(onErrorJustReturn: ("", [])))
        bindSendMessage(input.sendMessage)
        return Output(sender: senderSubject.asDriver(onErrorJustReturn: ICSender()),
                      messages: messageSubject.asDriver(onErrorJustReturn: []),
                      showErrorMsg: showErrorMsgSubject.asDriver(onErrorJustReturn: ""))
    }
}

//MARK: - Bind
extension ICChatViewModel {
    
    private func bindTrigger(_ trigger: Driver<Void>) {
        trigger
            .do(onNext: { [unowned self] (_) in
                self.senderSubject.onNext(ICSender(senderId: "\(self.userManager.uid())",
                                                   displayName: self.userManager.nickname()))
                self.chatManager.updateLastSeen(channelID: channelID)
            })
            .drive(onNext: { [unowned self] (_) in
                self.chatManager.pullHistory(channelID: channelID)
            })
            .disposed(by: disposeBag)
    }
    
    private func bindExit(_ exit: Driver<Void>) {
        exit
            .do(onNext: { [unowned self] (_) in
                self.chatManager.updateLastSeen(channelID: channelID)
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
                self.chatManager.sendMessage.onNext((self.channelID, data))
            })
            .disposed(by: disposeBag)
    }
    
    private func bindUpdateHistory(_ updateHistory: Driver<(String, [ICMessageData])>) {
        updateHistory
            .filter ({ [unowned self] (channelID, msgDatas) -> Bool in
                return self.channelID == channelID
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
                                      "channel_id": channelID,
                                      "payload": payload]
        do {
            let data = try JSONSerialization.data(withJSONObject: message, options: .prettyPrinted)
            return data
        } catch  {
            return nil
        }
    }
}

//MARK: - API
extension ICChatViewModel {
    private func apiUpdateReadDate(_ dateString: String, channelID: String, userID: Int) {
        chatAPIService
            .apiUpdateReadDate(channelID: channelID, userID: userID, date: dateString)
            .subscribe(onSuccess: { (member) in
                
            }, onError: { (error) in
                guard let err = error as? ICError else { return }
                self.showErrorMsgSubject.onNext("\(err.code ?? 0) \(err.msg ?? "")")
                print(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    private func apiShutdownChannel(channelID: String) {
        chatAPIService
            .apiShutdownChannel(channelID: channelID)
            .subscribe { (channelID) in
                print("關閉 \(channelID ?? "") 頻道!")
            } onError: { (error) in
                guard let err = error as? ICError else { return }
                self.showErrorMsgSubject.onNext("\(err.code ?? 0) \(err.msg ?? "")")
                print(error.localizedDescription)
            }
            .disposed(by: disposeBag)

    }
}
