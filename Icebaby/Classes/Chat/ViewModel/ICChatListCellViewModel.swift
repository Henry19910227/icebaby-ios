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
    private var nicknameSubject = ReplaySubject<String>.create(bufferSize: 1)
    
    //Input
    public var message = ReplaySubject<String>.create(bufferSize: 1)
    public var unreadCount = ReplaySubject<Int>.create(bufferSize: 1)
    
    //Output
    public var nickname: Driver<String>?
    public var latestMsg: Driver<String>?
    public var unread: Driver<Int>?
    
    init(userID: Int) {
        self.userID = userID
        super.init()
        nickname = nicknameSubject.asDriver(onErrorJustReturn: "")
        latestMsg = message.asDriver(onErrorJustReturn: "")
        unread = unreadCount.asDriver(onErrorJustReturn: 0)
    }
    
}

//MARK: - Bind Model
extension ICChatListCellViewModel {
    private func bindModel(_ model: ICChannel) {
        nicknameSubject.onNext(model.member?.info?.nickname ?? "")
        message.onNext(model.latestMsg?.payload?.body ?? "")
        unreadCount.onNext(model.unread ?? 0)
    }
}

//MARK: - Other
extension ICChatListCellViewModel {
    public func clear() {
        disposeBag = DisposeBag()
    }
}
