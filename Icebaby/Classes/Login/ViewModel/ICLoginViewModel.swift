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
    
    //Param
    private var identifier = ""
    private var password = ""
    
    
    struct Input {
        public let loginTap: Driver<Void>
        public let identifier: Driver<String?>
        public let password: Driver<String?>
    }
    
    struct Output {
        public let showLoading: Driver<Bool>
    }
    
    init(navigator: ICLoginRootNavigator, loginAPIService: ICLoginAPI) {
        self.navigator = navigator
        self.loginAPIService = loginAPIService
    }
    
    @discardableResult func transform(input: Input) -> Output {
        bindIdentifierDriver(input.identifier)
        bindPasswordDriver(input.password)
        bindLoginTap(input.loginTap)
        
        return Output(showLoading: showLoadingSubject.asDriver(onErrorJustReturn: false))
    }
}

//MARK: - Bind
extension ICLoginViewModel {
    private func bindLoginTap(_ loginTap: Driver<Void>) {
        loginTap
            .do(onNext: { [unowned self] (_) in
                self.apiUserLogin()
            })
            .drive()
            .disposed(by: disposeBag)
    }
    
    private func bindIdentifierDriver(_ identifierDriver: Driver<String?>) {
        identifierDriver
           .do(onNext: { [unowned self] (identifier) in
                self.identifier = identifier ?? ""
           })
           .drive()
           .disposed(by: disposeBag)
    }
    
    private func bindPasswordDriver(_ passwordDriver: Driver<String?>) {
        passwordDriver
           .do(onNext: { [unowned self] (password) in
                self.password = password ?? ""
           })
           .drive()
           .disposed(by: disposeBag)
    }
}

//MARK: - API
extension ICLoginViewModel {
    func apiUserLogin() {
        showLoadingSubject.onNext(true)
        loginAPIService
            .apiUserLogin(identifier: identifier, password: password)
            .subscribe(onSuccess: { [unowned self] (user) in
                self.showLoadingSubject.onNext(false)
                self.navigator.presendToMain()
            }) { [unowned self] (error) in
                self.showLoadingSubject.onNext(false)
                guard let e = error as? ICError else { return }
                print("錯誤碼 : \(e.code ?? 0)")
                print("錯誤訊息 : \(e.msg ?? "")")
            }
            .disposed(by: disposeBag)
    }
}
