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
    
    struct Input {
        public let chatTrigger: Driver<[String: Any]>
    }
    
    struct Output {
    }
    
    init(navigator: ICChatRootNavigator, chatAPIService: ICChatAPI) {
        self.navigator = navigator
        self.chatAPIService = chatAPIService
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
}
