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
    private var allowChat = false
    private var needToChat = false

    struct Input {
        public let trigger: Driver<Void>
        public let allowChat: Driver<Bool>
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
    }
}

//MARK: - Transform
extension ICUserViewModel {
    @discardableResult func transform(input: Input) -> Output {
        bindTrigger(input.trigger)
        bindChatTap(input.chatTap)
        bindAllowChat(input.allowChat)
//        bindOnPublish(chatManager.onPublish.asObservable())
        bindOnSubscribeSuccess(chatManager.onSubscribeSuccess.asDriver(onErrorJustReturn: ("", [ICMessageData]())))
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
                self.needToChat = true
                self.apiCreateAndActivateChannel(friendID: self.userID)
            }) 
            .drive()
            .disposed(by: disposeBag)
    }
    
    private func bindAllowChat(_ allowChat: Driver<Bool>) {
        allowChat
            .do(onNext: { [unowned self] (isAllow) in
                self.allowChat = isAllow
            })
            .drive()
            .disposed(by: disposeBag)
    }
    
    private func bindOnPublish(_ onPublish: Observable<ICMessageData?>) {
//        onPublish
//            .filter({ [unowned self] (_) -> Bool in
//                return self.allowChat
//            })
//            .filter({ (data) -> Bool in
//                return data?.type == "subscribe"
//            })
//            .map({ (data) -> String in
//                return data?.channelId ?? ""
//            })
//            .subscribe(onNext: { [unowned self] (channelID) in
//                self.chatManager.subscribeChannel(channelID)
//            })
//            .disposed(by: disposeBag)
    }
    
    private func bindOnSubscribeSuccess(_ onSubscribeSuccess: Driver<(String, [ICMessageData])>) {
        onSubscribeSuccess
            .filter({ [unowned self] (_) -> Bool in
                return self.allowChat && self.needToChat
            })
            .drive(onNext: { [unowned self] (channelID, _) in
                self.needToChat = false
                self.navigator?.toChat(channelID: channelID)
            })
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
    
    private func apiCreateAndActivateChannel(friendID: Int) {
        showLoadingSubject.onNext(true)
        chatAPIService
            .apiCreateChannel(friendID: friendID)
            .flatMap ({ [unowned self] (channelID) -> Single<String?> in
                return self.chatAPIService.apiActivateChannel(channelID: channelID ?? "")
            })
            .subscribe { [unowned self] (channelID) in
                self.showLoadingSubject.onNext(false)
                print("創建並激活 \(channelID ?? "") 頻道!")
            } onError: { [unowned self] (error) in
                self.showLoadingSubject.onNext(false)
                guard let err = error as? ICError else { return }
                self.showErrorMsgSubject.onNext("\(err.code ?? 0) \(err.msg ?? "")")
            }
            .disposed(by: disposeBag)
    }
}

