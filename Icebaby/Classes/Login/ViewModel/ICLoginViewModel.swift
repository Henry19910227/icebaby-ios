//
//  ICLoginViewModel.swift
//  Icebaby
//
//  Created by 廖冠翰 on 2020/11/27.
//

import UIKit
import RxSwift
import RxCocoa
import FBSDKCoreKit
import FBSDKLoginKit

enum ICRole: Int {
    case user = 1
    case girl = 2
}

class ICLoginViewModel: ICViewModel {

    //DI Param
    private let navigator: ICLoginRootNavigator
    private let loginAPIService: ICLoginAPI
    private let userManager: UserManager
    private let fbLoginManager: FBLoginManager
    
    //RX
    private let disposeBag = DisposeBag()
    
    //Subject
    private let showLoadingSubject = PublishSubject<Bool>()
    private let showErrorMsgSubject = PublishSubject<String>()
    private let defaultMobileSubject = PublishSubject<String>()
    
    //Param
    private var identifier = ""
    private var password = ""
    private var role = ICRole.user
    
    
    struct Input {
        public let trigger: Driver<Void>
        public let loginTap: Driver<Void>
        public let fbLoginTap: Driver<Void>
        public let identifier: Driver<String?>
        public let password: Driver<String?>
        public let role: Driver<Int>
    }
    
    struct Output {
        public let defaultMobile: Driver<String>
        public let showLoading: Driver<Bool>
        public let showErrorMsg: Driver<String>
    }
    
    init(navigator: ICLoginRootNavigator,
         loginAPIService: ICLoginAPI,
         fbLoginManager: FBLoginManager,
         userManager: UserManager) {
        self.navigator = navigator
        self.loginAPIService = loginAPIService
        self.userManager = userManager
        self.fbLoginManager = fbLoginManager
    }
    
    @discardableResult func transform(input: Input) -> Output {
        bindTrigger(input.trigger)
        bindIdentifierDriver(input.identifier)
        bindPasswordDriver(input.password)
        bindLoginTap(input.loginTap)
        bindFbLoginTap(input.fbLoginTap)
        bindRoleDriver(input.role)
        
        return Output(defaultMobile: defaultMobileSubject.asDriver(onErrorJustReturn: ""),
                      showLoading: showLoadingSubject.asDriver(onErrorJustReturn: false),
                      showErrorMsg: showErrorMsgSubject.asDriver(onErrorJustReturn: ""))
    }
}

//MARK: - Bind
extension ICLoginViewModel {
    private func bindTrigger(_ trigger: Driver<Void>) {
        trigger
            .do(onNext: { [unowned self] (_) in
                self.defaultMobileSubject.onNext(self.userManager.mobile())
                self.identifier = self.userManager.mobile()
            })
            .drive()
            .disposed(by: disposeBag)
    }
    
    private func bindLoginTap(_ loginTap: Driver<Void>) {
        loginTap
            .do(onNext: { [unowned self] (_) in
                self.apiUserLogin()
            })
            .drive()
            .disposed(by: disposeBag)
    }
    
    private func bindFbLoginTap(_ fbLoginTap: Driver<Void>) {
        fbLoginTap
            .do(onNext: { [unowned self] (_) in
                self.fbLoginManager
                    .login()
                    .drive(onNext: { (result) in
                        print(result["token"] as! String)
                    })
                    .disposed(by: self.disposeBag)
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
    
    private func bindRoleDriver(_ roleDriver: Driver<Int>) {
        roleDriver
            .map({ (index) -> ICRole in
                if index == 0 {
                    return .user
                }
                return .girl
            })
            .do(onNext: { [unowned self] (role) in
                self.role = role
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
            .apiUserLogin(identifier: identifier, password: password, role: role.rawValue)
            .do(onSuccess: { [unowned self] (_) in
                self.userManager.saveMobile(self.identifier)
            })
            .subscribe(onSuccess: { [unowned self] (uid, token, nickname) in
                print("Login uid:\(uid), nickname:\(nickname)")
                self.userManager.saveToken(token)
                self.userManager.saveUID(uid)
                self.userManager.saveNickname(nickname)
                self.showLoadingSubject.onNext(false)
                self.navigator.presendToMain()
            }) { [unowned self] (error) in
                self.showLoadingSubject.onNext(false)
                guard let err = error as? ICError else { return }
                self.showErrorMsgSubject.onNext("\(err.code ?? 0) \(err.msg ?? "")")
            }
            .disposed(by: disposeBag)
    }
}
