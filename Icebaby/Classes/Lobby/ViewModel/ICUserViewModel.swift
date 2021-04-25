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
    private let lobbyAPIService: ICLobbyAPI
    private let chatAPIService: ICChatAPI
    private let chatManager: ICChatManager
    private let userID: Int
    
    //Subject
    private let showLoadingSubject = PublishSubject<Bool>()
    private let showErrorMsgSubject = PublishSubject<String>()
    private let uidSubject = PublishSubject<Int>()
    private let nicknameSubject = PublishSubject<String>()
    private let birthdaySubject = PublishSubject<String>()
    private let switchTabSubject = PublishSubject<Int>()
    
    //Status
    private var isDisplay = false
    private var needToChat = false

    struct Input {
        public let trigger: Driver<Void>
        public let isDisplay: Driver<Bool>
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
    
    init(navigator: ICUserNavigator,
         lobbyAPIService: ICLobbyAPI,
         chatAPIService: ICChatAPI,
         chatManager: ICChatManager,
         userID: Int) {
        self.navigator = navigator
        self.lobbyAPIService = lobbyAPIService
        self.chatAPIService = chatAPIService
        self.chatManager = chatManager
        self.userID = userID
        bindOnActivate(chatManager.onActivate.asDriver(onErrorJustReturn: nil))
    }
    
    deinit {
        print("deinit ICUserViewModel")
    }
}

//MARK: - Transform
extension ICUserViewModel {
    @discardableResult func transform(input: Input) -> Output {
        bindTrigger(input.trigger)
        bindChatTap(input.chatTap)
        bindIsDisplay(input.isDisplay)
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
    private func bindTrigger(_ trigger: Driver<Void>) {
        trigger
            .do(onNext: { [unowned self] (_) in
                self.apiGetUserDetail(userID: self.userID)
            })
            .drive()
            .disposed(by: disposeBag)
    }
    
    private func bindChatTap(_ chatTap: Driver<Void>) {
        chatTap
            .do(onNext: { [unowned self] (_) in
                if let channel = self.chatManager.getChannelWithFriend(self.userID) { //已經存在該頻道
                    if channel.status == 1 {
                        self.navigator?.toChat(channel: channel)
                    } else {
                        self.chatManager.createChannel(friendID: self.userID)
                    }
                } else { //目前沒有開通所以創建頻道
                    self.chatManager.createChannel(friendID: self.userID)
                }
            }) 
            .drive()
            .disposed(by: disposeBag)
    }
    
    private func bindOnActivate(_ onActivate: Driver<ICChannel?>) {
        onActivate
            .filter({ [unowned self] (_) -> Bool in
                return self.isDisplay
            })
            .drive(onNext: { [unowned self] (channel) in
                guard let channel = channel else { return }
                self.navigator?.toChat(channel: channel)
            })
            .disposed(by: disposeBag)
    }
    
    private func bindIsDisplay(_ isDisplay: Driver<Bool>) {
        isDisplay
            .do(onNext: { [unowned self] (isDisplay) in
                self.isDisplay = isDisplay
            })
            .drive()
            .disposed(by: disposeBag)
    }
}

//MARK: - API
extension ICUserViewModel {
    private func apiGetUserDetail(userID: Int) {
        showLoadingSubject.onNext(true)
        lobbyAPIService
            .apiGetUserDetail(userID: userID)
            .subscribe(onSuccess: { [unowned self] (userDetail) in
                self.showLoadingSubject.onNext(false)
                self.uidSubject.onNext(userDetail?.id ?? 0)
                self.nicknameSubject.onNext(userDetail?.info?.nickname ?? "")
                self.birthdaySubject.onNext(userDetail?.info?.birthday ?? "")
            }, onError: { [unowned self] (error) in
                self.showLoadingSubject.onNext(false)
                guard let err = error as? ICError else { return }
                self.showErrorMsgSubject.onNext("\(err.code ?? 0) \(err.msg ?? "")")
            })
            .disposed(by: disposeBag)
    }
}

