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
    private let userManager: ICUserManager
    
    //RX
    private let disposeBag = DisposeBag()
    
    //Subject
    private let showLoadingSubject = PublishSubject<Bool>()
    private let showErrorMsgSubject = PublishSubject<String>()
    private let itemsSubject = PublishSubject<[ICChatListCellViewModel]>()
    
    
    struct Input {
        public let trigger: Driver<Void>
    }
    
    struct Output {
        public let showLoading: Driver<Bool>
        public let showErrorMsg: Driver<String>
        public let items: Driver<[ICChatListCellViewModel]>
    }
    
    init(navigator: ICChatRootNavigator,
         chatAPIService: ICChatAPI,
         chatManager: ICChatManager,
         userManager: ICUserManager) {
        self.navigator = navigator
        self.chatAPIService = chatAPIService
        self.chatManager = chatManager
        self.userManager = userManager
        bindOnPublish(chatManager.onPublish.asDriver(onErrorJustReturn: nil))
        bindOnSubscribeSuccess(chatManager.onSubscribeSuccess.asDriver(onErrorJustReturn: ""))
    }
}

//MARK: - transform
extension ICChatListViewModel {
    @discardableResult func transform(input: Input) -> Output {
        bindTrigger(trigger: input.trigger)
        return Output(showLoading: showLoadingSubject.asDriver(onErrorJustReturn: false),
                      showErrorMsg: showErrorMsgSubject.asDriver(onErrorJustReturn: ""),
                      items: itemsSubject.asDriver(onErrorJustReturn: []))
    }
}

//MARK: - bind
extension ICChatListViewModel {
    private func bindTrigger(trigger: Driver<Void>) {
        trigger
            .do(onNext: { [unowned self] (_) in
                self.apiGetMyChannels()
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
            .do(onSuccess: { (channels) in
                for channel in channels {
                    self.chatManager.subscribeChannel(String(channel.id ?? 0))
                }
            })
            .map({ [unowned self] (channels) -> [ICChatListCellViewModel] in
                return channels.map { [unowned self] (channel) -> ICChatListCellViewModel in
                    let vm = ICChatListCellViewModel(userID: self.userManager.uid())
                    vm.model = channel
                    return vm
                }
            })
            .subscribe(onSuccess: { [unowned self] (items) in
                self.showLoadingSubject.onNext(false)
                self.itemsSubject.onNext(items)
            }, onError: { [unowned self] (error) in
                self.showLoadingSubject.onNext(false)
                guard let err = error as? ICError else { return }
                self.showErrorMsgSubject.onNext("\(err.code ?? 0) \(err.msg ?? "")")
            })
            .disposed(by: disposeBag)
    }
}
