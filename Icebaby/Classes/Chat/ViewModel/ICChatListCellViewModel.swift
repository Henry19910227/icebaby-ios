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
    
    //Output
    public var nickname: Driver<String>?
    
    init(userID: Int) {
        self.userID = userID
    }
    
}

//MARK: - Bind Model
extension ICChatListCellViewModel {
    private func bindModel(_ model: ICChannel) {
        nickname = nicknameObservable(model).asDriver(onErrorJustReturn: "")
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
