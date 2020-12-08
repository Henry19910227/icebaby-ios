//
//  ICMainTabBarViewModel.swift
//  Icebaby
//
//  Created by Henry.Liao on 2020/12/8.
//

import UIKit
import RxSwift
import RxCocoa

class ICMainTabBarViewModel: ICViewModel {
    
    //RX
    private let disposeBag = DisposeBag()
    
    private let navigator: ICMainTabBarNavigator?
    private let chatManager: ICChatManager?
    
    struct Input {
        public let trigger: Driver<UITabBarController>
    }
    
    struct Output {

    }
    
    init(navigator: ICMainTabBarNavigator, chatManager: ICChatManager) {
        self.navigator = navigator
        self.chatManager = chatManager
    }
}

extension ICMainTabBarViewModel {
    @discardableResult func transform(input: Input) -> Output {
        bindTrigger(trigger: input.trigger)
        return Output()
    }
}

extension ICMainTabBarViewModel: APIToken {
    private func bindTrigger(trigger: Driver<UITabBarController>) {
        trigger
            .do(onNext: { [unowned self] (tabbarVC) in
                self.navigator?.toMain(tabbarVC: tabbarVC)
                self.chatManager?.start(token: token() ?? "")
            })
            .drive()
            .disposed(by: disposeBag)
    }
}
