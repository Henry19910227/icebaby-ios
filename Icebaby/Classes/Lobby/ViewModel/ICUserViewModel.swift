//
//  ICUserViewModel.swift
//  Icebaby
//
//  Created by 廖冠翰 on 2020/12/3.
//

import UIKit
import RxSwift
import RxCocoa

class ICUserViewModel: ICViewModel {
    
    //RX
    private let disposeBag = DisposeBag()
    
    //Param
    private let navigator: ICLobbyRootNavigator?
    private let lobbyAPIService: ICLobbyAPI?
    private let userID: Int

    struct Input {
        public let trigger: Driver<Void>
    }
    
    struct Output {
        
    }
    
    init(navigator: ICLobbyRootNavigator, lobbyAPIService: ICLobbyAPI, userID: Int) {
        self.navigator = navigator
        self.lobbyAPIService = lobbyAPIService
        self.userID = userID
    }
}

//MARK: - Transform
extension ICUserViewModel {
    @discardableResult func transform(input: Input) -> Output {
        return Output()
    }
}

//MARK: - Bind
extension ICUserViewModel {
    private func bindTrigger(trigger: Driver<Void>) {
        trigger
            .do(onNext: { [unowned self] (_) in
                self.apiGetUserDetail(userID: self.userID)
            })
            .drive()
            .disposed(by: disposeBag)
    }
}

//MARK: - API
extension ICUserViewModel {
    private func apiGetUserDetail(userID: Int) {
        lobbyAPIService?
            .apiGetUserDetail(userID: userID)
            .subscribe(onSuccess: { (userDetail) in
                
            }, onError: { (error) in
                
            })
            .disposed(by: disposeBag)
    }
}

