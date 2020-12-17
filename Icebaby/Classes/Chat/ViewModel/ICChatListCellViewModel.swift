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
    
    //Rx
    private var disposeBag = DisposeBag()
    
    //Input
    public var message = PublishSubject<String>()
    
    //Output
    public var nickname: Driver<String>?
    public var latestMsg: Driver<String>?
    
    init(userID: Int) {
        self.userID = userID
        super.init()
        bindMessage(message.asDriver(onErrorJustReturn: ""))
    }
    
}

//MARK: - Bind Model
extension ICChatListCellViewModel {
    private func bindModel(_ model: ICChannel) {
        nickname = nicknameObservable(model).asDriver(onErrorJustReturn: "")
    }
    
    private func bindMessage(_ message: Driver<String>) {
        latestMsg = message
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
