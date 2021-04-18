//
//  ICMeViewModel.swift
//  Icebaby
//
//  Created by Henry.Liao on 2021/4/16.
//

import UIKit
import RxCocoa
import RxSwift
import SwiftyJSON

class ICMeViewModel: NSObject {
    
    //RX
    private let disposeBag = DisposeBag()
    
    private let loginAPIService: ICLoginAPI?
    private let chatManager: ICChatManager?
    
    struct Input {
        public let logout: Driver<Void>
    }
    
    struct Output {
        
    }
    
    init(loginAPIService: ICLoginAPI, chatManager: ICChatManager) {
        self.loginAPIService = loginAPIService
        self.chatManager = chatManager
    }
}



// MARK: - Transform
extension ICMeViewModel {
    @discardableResult func transform(input: Input) -> Output {
        bindLogout(input.logout)
        return Output()
    }
}

// MARK: - Bind
extension ICMeViewModel {
    private func bindLogout(_ logout: Driver<Void>) {
        logout.do { [unowned self] (_) in
            self.apiLogout()
        }
        .drive()
        .disposed(by: disposeBag)

    }
}

// MARK: - API
extension ICMeViewModel {
    private func apiLogout() {
        loginAPIService?
            .apiLogout()
            .subscribe(onSuccess: { [unowned self]  (_) in
                self.chatManager?.disconnect()
            }, onError: { (error) in
                
            })
            .disposed(by: disposeBag)
    }
}
