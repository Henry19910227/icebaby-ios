//
//  ICChatListViewMocel.swift
//  Icebaby
//
//  Created by Henry.Liao on 2020/12/3.
//

import UIKit
import RxSwift
import RxCocoa

class ICChatListViewModel: ICViewModel {
    
    //RX
    private let disposeBag = DisposeBag()
    
    //Dependency Injection
    private let navigator: ICChatRootNavigator?
    private let chatAPIService: ICChatAPI?
    private let chatManager: ICChatManager
    
    struct Input {
        public let chatTrigger: Driver<[String: Any]>
    }
    
    struct Output {
    }
    
    init(navigator: ICChatRootNavigator, chatAPIService: ICChatAPI, chatManager: ICChatManager) {
        self.navigator = navigator
        self.chatAPIService = chatAPIService
        self.chatManager = chatManager
        bindOnPublish(chatManager.onPublish.asDriver(onErrorJustReturn: nil))
    }
}

//MARK: - transform
extension ICChatListViewModel {
    @discardableResult func transform(input: Input) -> Output {
        bindChatTrigger(trigger: input.chatTrigger)
        return Output()
    }
}

//MARK: - bind
extension ICChatListViewModel {
    private func bindChatTrigger(trigger: Driver<[String: Any]>) {
        trigger
            .do(onNext: { (userinfo) in
                print("id:\(userinfo["uid"] as? Int ?? 0)")
            })
            .drive()
            .disposed(by: disposeBag)
    }
    
    private func bindOnPublish(_ onPublish: Driver<ICChatData?>) {
        onPublish
            .do(onNext: { (info) in
                print("channel:\(info?.channel ?? ""), uid:\(info?.uid ?? 0), type:\(info?.type ?? ""), msg:\(info?.msg ?? "")" )
            })
            .drive()
            .disposed(by: disposeBag)
    }
    
    private func bindOnSubscribeSuccess(_ onSubscribeSuccess: Driver<String>) {
        
    }
}

//MARK: - API
extension ICChatListViewModel {
    
}
