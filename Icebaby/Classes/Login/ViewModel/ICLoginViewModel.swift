//
//  ICLoginViewModel.swift
//  Icebaby
//
//  Created by 廖冠翰 on 2020/11/27.
//

import UIKit
import RxSwift
import RxCocoa

class ICLoginViewModel: ICViewModel {

    //DI Param
    private let navigator: ICLoginRootNavigator
    private let loginAPIService: ICLoginAPI
    
    //RX
    private let disposeBag = DisposeBag()
    
    //Subject
    private let showLoadingSubject = PublishSubject<Bool>()
    
    
    struct Input {
        public let loginTap: Driver<Void>
    }
    
    struct Output {
        public let showLoading: Driver<Bool>
    }
    
    init(navigator: ICLoginRootNavigator, loginAPIService: ICLoginAPI) {
        self.navigator = navigator
        self.loginAPIService = loginAPIService
    }
    
    @discardableResult func transform(input: Input) -> Output {
        input
            .loginTap.do(onNext: { [unowned self] (_) in
                self.apiUserLogin()
            })
            .drive()
            .disposed(by: disposeBag)
        return Output(showLoading: showLoadingSubject.asDriver(onErrorJustReturn: false))
    }
}

extension ICLoginViewModel {
    func apiUserLogin() {
        showLoadingSubject.onNext(true)
        loginAPIService
            .apiUserLogin(identifier: "0978820789", password: "12345678")
            .subscribe(onSuccess: { [unowned self] (user) in
                self.showLoadingSubject.onNext(false)
                self.navigator.presendToMain()
            }) { [unowned self] (error) in
                self.showLoadingSubject.onNext(false)
            }
            .disposed(by: disposeBag)
        
    }
}
