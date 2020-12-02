//
//  ICLobbyViewModel.swift
//  Icebaby
//
//  Created by Henry.Liao on 2020/12/2.
//

import UIKit
import RxSwift
import RxCocoa

class ICLobbyViewModel: ICViewModel {
    
    //RX
    private let disposeBag = DisposeBag()
    
    //Param
    private let navigator: ICLobbyRootNavigator?
    private let lobbyAPIService: ICLobbyAPI?
    
    struct Input {
        public let trigger: Driver<Void>
    }
    
    struct Output {
        
    }

    init(navigator: ICLobbyRootNavigator, lobbyAPIService: ICLobbyAPI) {
        self.navigator = navigator
        self.lobbyAPIService = lobbyAPIService
    }
}

// MARK: - Transform
extension ICLobbyViewModel {
    @discardableResult func transform(input: Input) -> Output {
        bindTrigger(trigger: input.trigger)
        return Output()
    }
}

// MARK: - Bind
extension ICLobbyViewModel {
    private func bindTrigger(trigger: Driver<Void>) {
        trigger
            .do(onNext: { [unowned self] (_) in
                self.apiGetUserList()
            })
            .drive()
            .disposed(by: disposeBag)
    }
}

// MARK: - API
extension ICLobbyViewModel {
    private func apiGetUserList() {
        lobbyAPIService?
            .apiGetUserList()
            .subscribe(onSuccess: { (users) in
                
            },onError: { (error) in
                
            })
            .disposed(by: disposeBag)
    }
}


