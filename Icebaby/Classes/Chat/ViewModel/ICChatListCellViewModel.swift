//
//  ICChatListCellViewModel.swift
//  Icebaby
//
//  Created by 廖冠翰 on 2020/12/11.
//

import UIKit
import RxCocoa
import RxSwift

class ICChatListCellViewModel: NSObject {
    
    //Model
    public var model: ICChannel? {
        didSet {
            guard let model = model else { return }
            bindModel(model)
        }
    }
    
    //DI
    private var userID: Int
    private var chatManager: ICChatManager
    
    //Data
//    private var
    
    //Rx
    private var disposeBag = DisposeBag()
    
    //Output
    public var nickname: Driver<String>?
    
    init(userID: Int, chatManager: ICChatManager) {
        self.userID = userID
        self.chatManager = chatManager
        super.init()
        self.bindOnSubscribeSuccess(chatManager.onSubscribeSuccess.asDriver(onErrorJustReturn: ""))
    }
    
    deinit {
        print("deinit \(self)")
    }
    
}

//MARK: - Bind Model
extension ICChatListCellViewModel {
    private func bindModel(_ model: ICChannel) {
        nickname = nicknameObservable(model).asDriver(onErrorJustReturn: "")
    }
    private func bindOnSubscribeSuccess(_ onSubscribeSuccess: Driver<String>) {
        onSubscribeSuccess
            .filter({ [unowned self] (channelID) -> Bool in
                return self.model?.id ?? "" == channelID
            })
            .drive(onNext: { (channelID) in
                print("VM : \(channelID) \(self)")
//                self.chatManager.history(channelID: channelID) { (datas) in
//                    print("latest msg : \(datas.last?.message?.msg ?? "")")
//                }
            })
            .disposed(by: disposeBag)
    }
}

//MARK: - Observable
extension ICChatListCellViewModel {
    private func nicknameObservable(_ model: ICChannel) -> Observable<String> {
        return Observable<ICChannel>
                .just(model)
                .map ({ [unowned self] (channel) -> String in
                    var nickname = ""
                    for member in model.members ?? [] {
                        if (member.userID != self.userID) {
                            nickname = member.nickname ?? ""
                        }
                    }
                    return nickname
                })
    }
}

//MARK: - Other
extension ICChatListCellViewModel {
    public func clear() {
        disposeBag = DisposeBag()
    }
}
