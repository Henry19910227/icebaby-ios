//
//  ICChatViewModel.swift
//  Icebaby
//
//  Created by Henry.Liao on 2020/12/15.
//

import UIKit
import RxCocoa
import RxSwift

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
    
    struct Input {
        public let sendMessage: Driver<String>
    }
    
    struct Output {
        
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
        bindSendMessage(input.sendMessage)
        return Output()
    }
}

//MARK: - Bind
extension ICChatViewModel {
    private func bindSendMessage(_ sendMessage: Driver<String>) {
        sendMessage
            .map({ (text) -> ICChatData in
                
                return ICChatData()
            })
            .drive(onNext: { (_) in
                
            })
            .disposed(by: disposeBag)
    }
}

//MARK: - Other
extension ICChatViewModel {
    private func getChatData(text: String) -> Data? {
        let date = dateFormatter.dateToDateString(Date(), "yyyy-mm-dd HH:mm:ss") ?? ""
        let msdId = "\(userManager.uid())-" + date
        let chatMsg = ICChatMsg(id: msdId,
                                date: date,
                                uid: userManager.uid(),
                                nickname: userManager.nickname(),
                                msg: text)
        let chatData = ICChatData(type: "message",
                                  channelId: channelID,
                                  message: chatMsg)
        do {
            let data = try JSONSerialization.data(withJSONObject: chatData, options: .prettyPrinted)
            return data
        } catch  {
            return nil
        }
    }
}
