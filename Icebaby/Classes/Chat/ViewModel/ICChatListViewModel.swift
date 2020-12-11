//
//  ICChatListViewMocel.swift
//  Icebaby
//
//  Created by Henry.Liao on 2020/12/3.
//

import UIKit
import RxSwift
import RxCocoa

class ICChatListViewModel: ICViewModel {
    
    //Dependency Injection
    private let navigator: ICChatRootNavigator?
    private let chatAPIService: ICChatAPI?
    private let chatManager: ICChatManager
    
    //RX
    private let disposeBag = DisposeBag()
    
    //Subject
    private let showLoadingSubject = PublishSubject<Bool>()
    private let showErrorMsgSubject = PublishSubject<String>()
    
    
    struct Input {
        public let chatTrigger: Driver<[String: Any]>
    }
    
    struct Output {
        public let showLoading: Driver<Bool>
        public let showErrorMsg: Driver<String>
    }
    
    init(navigator: ICChatRootNavigator, chatAPIService: ICChatAPI, chatManager: ICChatManager) {
        self.navigator = navigator
        self.chatAPIService = chatAPIService
        self.chatManager = chatManager
        bindOnPublish(chatManager.onPublish.asDriver(onErrorJustReturn: nil))
        bindOnSubscribeSuccess(chatManager.onSubscribeSuccess.asDriver(onErrorJustReturn: ""))
    }
}

//MARK: - transform
extension ICChatListViewModel {
    @discardableResult func transform(input: Input) -> Output {
        bindChatTrigger(trigger: input.chatTrigger)
        return Output(showLoading: showLoadingSubject.asDriver(onErrorJustReturn: false),
                      showErrorMsg: showErrorMsgSubject.asDriver(onErrorJustReturn: ""))
    }
}

//MARK: - bind
extension ICChatListViewModel {
    private func bindChatTrigger(trigger: Driver<[String: Any]>) {
        trigger
            .do(onNext: { [unowned self] (userinfo) in
                let guestID = userinfo["uid"] as? Int ?? 0
                self.apiNewChat(guestID: guestID)
            })
            .drive()
            .disposed(by: disposeBag)
    }
    
    private func bindOnPublish(_ onPublish: Driver<ICChatData?>) {
        onPublish
            .filter({ (data) -> Bool in
                return data?.type == "subscribe"
            })
            .drive(onNext: { [unowned self] (data) in
                self.apiGetMyChannels()
                self.chatManager.subscribeChannel(data?.content)
            })
            .disposed(by: disposeBag)
        
        onPublish
            .filter({ (data) -> Bool in
                return data?.type == "message"
            })
            .drive(onNext: { (data) in
                print("message : \(data?.content ?? "")")
            })
            .disposed(by: disposeBag)
    }
    
    private func bindOnSubscribeSuccess(_ onSubscribeSuccess: Driver<String>) {
        onSubscribeSuccess
            .do(onNext: { (channel) in
                print("Subscribe channel : \(channel)")
             })
            .drive()
            .disposed(by: disposeBag)
    }
}

//MARK: - API
extension ICChatListViewModel {
    private func apiNewChat(guestID: Int) {
        showLoadingSubject.onNext(true)
        chatAPIService?
            .apiNewChat(guestID: guestID)
            .subscribe(onSuccess: { [unowned self] (channelID) in
                self.showLoadingSubject.onNext(false)
            }, onError: { [unowned self] (error) in
                self.showLoadingSubject.onNext(false)
                guard let err = error as? ICError else { return }
                self.showErrorMsgSubject.onNext("\(err.code ?? 0) \(err.msg ?? "")")
            })
            .disposed(by: disposeBag)
    }
    
    private func apiGetMyChannels() {
        showLoadingSubject.onNext(true)
        chatAPIService?
            .apiGetMyChannel()
            .subscribe(onSuccess: { [unowned self] (channels) in
                self.showLoadingSubject.onNext(true)
                for channel in channels {
                    print("member : \(channel.members?.count ?? 0)")
                }
            }, onError: { [unowned self] (error) in
                self.showLoadingSubject.onNext(true)
                guard let err = error as? ICError else { return }
                self.showErrorMsgSubject.onNext("\(err.code ?? 0) \(err.msg ?? "")")
            })
            .disposed(by: disposeBag)
    }
}
