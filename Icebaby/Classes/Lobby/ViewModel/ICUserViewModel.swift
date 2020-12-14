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

    struct Input {
        public let trigger: Driver<Bool>
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
        let onPublish = Observable.zip(chatManager.onPublish.asObservable(),
                                          input.trigger.asObservable()).filter({ $1 })
        let onSubscribe = Observable.zip(chatManager.onSubscribeSuccess.asObservable(),
                                         input.trigger.asObservable()).filter({ $1 }).asDriver(onErrorJustReturn: ("", false))
        bindTrigger(trigger: input.trigger)
        bindChatTap(chatTap: input.chatTap)
        bindOnPublish(onPublish)
        bindOnSubscribeSuccess(onSubscribe)
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
    private func bindTrigger(trigger: Driver<Bool>) {
        trigger
            .filter({ $0 })
            .do(onNext: { [unowned self] (_) in
                self.apiGetUserDetail(userID: self.userID)
            })
            .drive()
            .disposed(by: disposeBag)
    }
    
    private func bindChatTap(chatTap: Driver<Void>) {
        chatTap
            .do(onNext: { [unowned self] (_) in
                self.apiNewChat(guestID: self.userID)
            }) 
            .drive()
            .disposed(by: disposeBag)
    }
    
    private func bindOnPublish(_ onPublish: Observable<(ICChatData?, Bool)>) {
        onPublish
            .filter({ (data, _) -> Bool in
                return data?.type == "subscribe"
            })
            .map({ (data,_) -> String in
                return data?.content ?? ""
            })
            .subscribe(onNext: { [unowned self] (channelID) in
                self.chatManager.subscribeChannel(channelID)
            })
            .disposed(by: disposeBag)

        
//        onPublish
//            .filter({ (data, _) -> Bool in
//                return data?.type == "message"
//            })
//            .subscribe(onNext: { (data,_) in
//                print("message : \(data?.content ?? "")")
//            })
//            .disposed(by: disposeBag)
    }
    
    private func bindOnSubscribeSuccess(_ onSubscribeSuccess: Driver<(String, Bool)>) {
        onSubscribeSuccess
            .drive(onNext: { [unowned self] (channel, _) in
                self.navigator?.toChat(channelID: channel)
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
                self.nicknameSubject.onNext(userDetail?.nickname ?? "")
                self.birthdaySubject.onNext(userDetail?.birthday ?? "")
            }, onError: { [unowned self] (error) in
                self.showLoadingSubject.onNext(false)
                guard let err = error as? ICError else { return }
                self.showErrorMsgSubject.onNext("\(err.code ?? 0) \(err.msg ?? "")")
            })
            .disposed(by: disposeBag)
    }
    
    private func apiNewChat(guestID: Int) {
        showLoadingSubject.onNext(true)
        chatAPIService
            .apiNewChat(guestID: guestID)
            .subscribe { (channelID) in
                self.showLoadingSubject.onNext(false)
            } onError: { (error) in
                self.showLoadingSubject.onNext(false)
                guard let err = error as? ICError else { return }
                self.showErrorMsgSubject.onNext("\(err.code ?? 0) \(err.msg ?? "")")
            }
            .disposed(by: disposeBag)

    }
}

