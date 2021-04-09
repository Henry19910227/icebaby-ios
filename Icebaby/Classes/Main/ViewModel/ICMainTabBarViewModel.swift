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
    private let userManager: UserManager
    private let showLoadingSubject = PublishSubject<Bool>()
    private let showErrorMsgSubject = PublishSubject<String>()
    
    struct Input {
        public let trigger: Driver<UITabBarController>
    }
    
    struct Output {
        public let showLoading: Driver<Bool>
        public let showErrorMsg: Driver<String>
    }
    
    init(navigator: ICMainTabBarNavigator, chatManager: ICChatManager, userManager: UserManager) {
        self.navigator = navigator
        self.chatManager = chatManager
        self.userManager = userManager
    }
}

extension ICMainTabBarViewModel {
    @discardableResult func transform(input: Input) -> Output {
        bindTrigger(trigger: input.trigger)
        return Output(showLoading: showLoadingSubject.asDriver(onErrorJustReturn: false),
                      showErrorMsg: showErrorMsgSubject.asDriver(onErrorJustReturn: ""))
    }
}

extension ICMainTabBarViewModel {
    private func bindTrigger(trigger: Driver<UITabBarController>) {
        trigger
            .do(onNext: { [unowned self] (tabbarVC) in
                self.navigator?.toMain(tabbarVC: tabbarVC)
                self.chatManager?.connect(token: self.userManager.token() ?? "", uid: self.userManager.uid())
            })
            .drive()
            .disposed(by: disposeBag)
    }
}
