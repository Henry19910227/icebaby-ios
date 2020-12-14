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
        public let trigger: Driver<Bool>
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
    }
}

//MARK: - transform
extension ICChatListViewModel {
    @discardableResult func transform(input: Input) -> Output {
        let onPublish = Observable.combineLatest(chatManager.onPublish.asObservable(),
                                          input.trigger.asObservable()).filter({ $1 })
        let onSubscribe = Observable.combineLatest(chatManager.onSubscribeSuccess.asObservable(),
                                                   input.trigger.asObservable()).filter({ $1 })
        bindTrigger(trigger: input.trigger)
        bindOnPublish(onPublish)
        bindOnSubscribeSuccess(onSubscribe)
        return Output(showLoading: showLoadingSubject.asDriver(onErrorJustReturn: false),
                      showErrorMsg: showErrorMsgSubject.asDriver(onErrorJustReturn: ""),
                      items: itemsSubject.asDriver(onErrorJustReturn: []))
    }
}

//MARK: - bind
extension ICChatListViewModel {
    private func bindTrigger(trigger: Driver<Bool>) {
        trigger
            .filter({ $0 })
            .do(onNext: { [unowned self] (_) in
                self.apiGetMyChannels()
            })
            .drive()
            .disposed(by: disposeBag)
    }
    
    private func bindOnPublish(_ onPublish: Observable<(ICChatData?, Bool)>) {
        onPublish
            .filter({ (data, _) -> Bool in
                return data?.type == "subscribe"
            })
            .subscribe(onNext: { [unowned self] (_,_) in
                self.apiGetMyChannels()
            })
            .disposed(by: disposeBag)

        
        onPublish
            .filter({ (data, _) -> Bool in
                return data?.type == "message"
            })
            .subscribe(onNext: { (data,_) in
                print("message : \(data?.content ?? "")")
            })
            .disposed(by: disposeBag)
    }
    
    private func bindOnSubscribeSuccess(_ onSubscribeSuccess: Observable<(String, Bool)>) {
        onSubscribeSuccess
            .subscribe(onNext: { (channel, _) in
                print("Subscribe channel : \(channel)")
            })
            .disposed(by: disposeBag)
    }
}

//MARK: - API
extension ICChatListViewModel {
    
    private func apiGetMyChannels() {
        showLoadingSubject.onNext(true)
        chatAPIService?
            .apiGetMyChannel()
            .do(onSuccess: { [unowned self] (channels) in
                for channel in channels {
                    self.chatManager.subscribeChannel(channel.id)
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
