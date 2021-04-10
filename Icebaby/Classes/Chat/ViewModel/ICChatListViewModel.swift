//
//  ICChatListViewMocel.swift
//  Icebaby
//
//  Created by Henry.Liao on 2020/12/3.
//

import UIKit
import RxSwift
import RxCocoa
import MessageKit

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
    private let itemsSubject = ReplaySubject<[ICChatListCellViewModel]>.create(bufferSize: 1)
    
    //Status
    private var allowChat = false
    
    //Data
    private var channels: [ICChannel] = []
    private var items: [ICChatListCellViewModel] = []
    private var cellVMs: [ICChatListCellViewModel] = []
    
    //Tool
    private var dateFormatter = ICDateFormatter()
    
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
        bindLatestMsg(chatManager.latestMessage.asObservable())
        bindChannels(chatManager.channelsSubject.asDriver(onErrorJustReturn: []))
        bindOnSubscribeSuccess(chatManager.onSubscribeSuccess.asDriver(onErrorJustReturn: ("", [])))
        bindUnreadCount(chatManager.unreadCount.asDriver(onErrorJustReturn: ("", 0)))
        return Output(showLoading: showLoadingSubject.asDriver(onErrorJustReturn: false),
                      showErrorMsg: showErrorMsgSubject.asDriver(onErrorJustReturn: ""),
                      items: itemsSubject.asDriver(onErrorJustReturn: []))
    }
}

//MARK: - bind
extension ICChatListViewModel {
    private func bindTrigger(_ trigger: Driver<Void>) {
        trigger
            .drive()
            .disposed(by: disposeBag)
    }
    
    private func bindChannels(_ channelsRelay: Driver<[ICChannel]>) {
        channelsRelay
            .map({ [unowned self] (channels) -> [ICChatListCellViewModel] in
                return channels.map { [unowned self] (channel) -> ICChatListCellViewModel in
                    let vm = ICChatListCellViewModel(userID: self.userManager.uid())
                    vm.model = channel
                    return vm
                }
            })
            .do { [unowned self] (vms) in
                self.cellVMs = vms
                self.itemsSubject.onNext(vms)
            }
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
    
    private func bindLatestMsg(_ onPublish: Observable<ICMessageData?>) {
        onPublish
            .filter({ (data) -> Bool in
                return data?.type == "message"
            })
            .subscribe(onNext: { [unowned self] (data) in
                guard let data = data else { return }
                guard let channelID = data.channelId else { return }
                self.setCellVMLatestText(channelID: channelID, msg: data.payload?.msg ?? "")
            })
            .disposed(by: disposeBag)
    }
    
    private func bindOnSubscribeSuccess(_ onSubscribeSuccess: Driver<(String, [ICMessageData])>) {
        onSubscribeSuccess
            .filter({ [unowned self] (_) -> Bool in
                return self.allowChat
            })
            .drive(onNext: { [unowned self] (channelID, chatDatas) in
                self.setCellVMLatestText(channelID: channelID, msg: chatDatas.last?.payload?.msg ?? "")
            })
            .disposed(by: disposeBag)
    }
    
    private func bindUnreadCount(_ unreadCount: Driver<(String, Int)>) {
        unreadCount
            .do(onNext: { [unowned self] (channelID, count) in
                self.setCellVMUnread(channelID: channelID, count: count)
            })
            .drive()
            .disposed(by: disposeBag)
    }
}

//MARK: - API
extension ICChatListViewModel {
    
    private func loadChannels() {
        self.channels = chatManager.getChannelDatas()
        self.cellVMs = channels.map { [unowned self] (channel) -> ICChatListCellViewModel in
            let vm = ICChatListCellViewModel(userID: self.userManager.uid())
            vm.model = channel
            return vm
        }
        self.itemsSubject.onNext(self.cellVMs)
    }
    
    private func apiGetHistories() {
        chatAPIService?
            .apiHistories(channelIDs: [String](), page: 1, size: 1)
            .subscribe(onSuccess: { (result) in
                print(result)
            }, onError: { (error) in
                self.showLoadingSubject.onNext(false)
                guard let err = error as? ICError else { return }
                self.showErrorMsgSubject.onNext("\(err.code ?? 0) \(err.msg ?? "")")
            })
            .disposed(by: disposeBag)
    }
}

//MARK: - Setup VM
extension ICChatListViewModel {
    private func setCellVMLatestText(channelID: String, msg: String) {
        for vm in cellVMs {
            if vm.model?.id ?? "" == channelID {
                vm.message.onNext(msg)
            }
        }
    }
    
    private func setCellVMUnread(channelID: String, count: Int) {
        for vm in cellVMs {
            if vm.model?.id ?? "" == channelID {
                vm.unreadCount.onNext(count)
            }
        }
    }
}
