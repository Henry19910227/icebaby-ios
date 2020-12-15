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
    
    //Status
    private var allowChat = false
    private var channels: [ICChannel] = []
    
    struct Input {
        public let trigger: Driver<Void>
        public let allowChat: Driver<Bool>
        public let itemSelected: Driver<IndexPath>
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
        bindTrigger(input.trigger)
        bindAllowChat(input.allowChat)
        bindItemSelected(input.itemSelected)
        bindOnPublish(chatManager.onPublish.asObservable())
        bindOnSubscribeSuccess(chatManager.onSubscribeSuccess.asDriver(onErrorJustReturn: ""))
        return Output(showLoading: showLoadingSubject.asDriver(onErrorJustReturn: false),
                      showErrorMsg: showErrorMsgSubject.asDriver(onErrorJustReturn: ""),
                      items: itemsSubject.asDriver(onErrorJustReturn: []))
    }
}

//MARK: - bind
extension ICChatListViewModel {
    private func bindTrigger(_ trigger: Driver<Void>) {
        trigger
            .do(onNext: { [unowned self] (_) in
                self.apiGetMyChannels()
            })
            .drive()
            .disposed(by: disposeBag)
    }
    
    private func bindItemSelected(_ itemSelected: Driver<IndexPath>) {
        itemSelected
            .map({ [unowned self] (indexPath) -> String in
                return self.channels[indexPath.row].id ?? ""
            })
            .do (onNext:{ [unowned self] (channelID) in
                self.navigator?.toChat(channelID: channelID)
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
    
    private func bindOnPublish(_ onPublish: Observable<ICChatData?>) {
        onPublish
            .filter({ [unowned self] (_) -> Bool in
                return self.allowChat
            })
            .filter({ (data) -> Bool in
                return data?.type == "subscribe"
            })
            .subscribe(onNext: { [unowned self] (_) in
                self.apiGetMyChannels()
            })
            .disposed(by: disposeBag)

        
        onPublish
            .filter({ [unowned self] (_) -> Bool in
                return self.allowChat
            })
            .filter({ (data) -> Bool in
                return data?.type == "message"
            })
            .subscribe(onNext: { (data) in
                let message = ICMessage(data: data?.message ?? ICChatMsg())
                print(message.messageId)
            })
            .disposed(by: disposeBag)
    }
    
    private func bindOnSubscribeSuccess(_ onSubscribeSuccess: Driver<String>) {
        onSubscribeSuccess
            .filter({ [unowned self] (_) -> Bool in
                return self.allowChat
            })
            .drive(onNext: { (channelID) in
                
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
                self.channels = channels
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
