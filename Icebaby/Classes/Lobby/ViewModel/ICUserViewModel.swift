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
    
    //Dependency Injection
    private let navigator: ICUserNavigator?
    private let lobbyAPIService: ICLobbyAPI?
    private let userID: Int
    
    //Subject
    private let showLoadingSubject = PublishSubject<Bool>()
    private let showErrorMsgSubject = PublishSubject<String>()
    private let uidSubject = PublishSubject<Int>()
    private let nicknameSubject = PublishSubject<String>()
    private let birthdaySubject = PublishSubject<String>()
    private let switchTabSubject = PublishSubject<Int>()

    struct Input {
        public let trigger: Driver<Void>
        public let chatTap: Driver<Void>
    }
    
    struct Output {
        public let showLoading: Driver<Bool>
        public let showErrorMsg: Driver<String>
        public let uid: Driver<Int>
        public let nickname: Driver<String>
        public let birthday: Driver<String>
        public let switchTab: Driver<Int>
    }
    
    init(navigator: ICUserNavigator, lobbyAPIService: ICLobbyAPI, userID: Int) {
        self.navigator = navigator
        self.lobbyAPIService = lobbyAPIService
        self.userID = userID
    }
}

//MARK: - Transform
extension ICUserViewModel {
    @discardableResult func transform(input: Input) -> Output {
        bindTrigger(trigger: input.trigger)
        bindChatTap(chatTap: input.chatTap)
        return Output(showLoading: showLoadingSubject.asDriver(onErrorJustReturn: false),
                      showErrorMsg: showErrorMsgSubject.asDriver(onErrorJustReturn: ""),
                      uid: uidSubject.asDriver(onErrorJustReturn: 0),
                      nickname: nicknameSubject.asDriver(onErrorJustReturn: ""),
                      birthday: birthdaySubject.asDriver(onErrorJustReturn: ""),
                      switchTab: switchTabSubject.asDriver(onErrorJustReturn: 0))
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
    
    private func bindChatTap(chatTap: Driver<Void>) {
        chatTap
            .do(onNext: { [unowned self] (_) in
                self.switchTabSubject.onNext(1)
                self.post()
            }) 
            .drive()
            .disposed(by: disposeBag)
    }
}

//MARK: - API
extension ICUserViewModel {
    private func apiGetUserDetail(userID: Int) {
        showLoadingSubject.onNext(true)
        lobbyAPIService?
            .apiGetUserDetail(userID: userID)
            .subscribe(onSuccess: { [unowned self] (userDetail) in
                self.showLoadingSubject.onNext(false)
                self.uidSubject.onNext(userDetail?.id ?? 0)
                self.nicknameSubject.onNext(userDetail?.nickname ?? "")
                self.birthdaySubject.onNext(userDetail?.birthday ?? "")
            }, onError: { [unowned self] (error) in
                self.showLoadingSubject.onNext(false)
                guard let err = error as? ICError else { return }
                self.showErrorMsgSubject.onNext("\(err.code ?? 0) \(err.msg ?? "")")
            })
            .disposed(by: disposeBag)
    }
}

extension ICUserViewModel {
    private func post() {
        let name = Notification.Name(rawValue: "StartNewChat")
        NotificationCenter.default.post(name: name, object: nil, userInfo: ["uid": self.userID])
    }
}

