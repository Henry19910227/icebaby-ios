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
    
    //Data
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
        bindChannels(chatManager.channels.asDriver(onErrorJustReturn: []))
        bindUpdateChannel(chatManager.updateChannel.asDriver(onErrorJustReturn: nil))
        bindAddChannel(chatManager.addChannel.asDriver(onErrorJustReturn: nil))
    }
}

//MARK: - transform
extension ICChatListViewModel {
    @discardableResult func transform(input: Input) -> Output {
        bindTrigger(input.trigger)
        bindItemSelected(input.itemSelected)
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
                self.chatManager.getMyChannels()
            })
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
            .map({ [unowned self] (indexPath) -> ICChannel? in
                return self.cellVMs[indexPath.row].model
            })
            .do (onNext:{ [unowned self] (channel) in
                guard let channel = channel else { return }
                self.navigator?.toChat(channel: channel)
            })
            .drive()
            .disposed(by: disposeBag)
    }
    
    private func bindUpdateChannel(_ updateChannelDriver: Driver<ICChannel?>) {
        updateChannelDriver
            .drive(onNext: { [unowned self] (channel) in
                self.updateCellVmModel(channel: channel)
            })
            .disposed(by: disposeBag)
    }
    
    private func bindAddChannel(_ addChannel: Driver<ICChannel?>) {
        addChannel
            .map({ [unowned self] (channel) -> ICChatListCellViewModel in
                let vm = ICChatListCellViewModel(userID: self.userManager.uid())
                vm.model = channel
                return vm
            })
            .drive(onNext: { [unowned self] (vm) in
                self.cellVMs.insert(vm, at: 0)
                self.itemsSubject.onNext(self.cellVMs)
            })
            .disposed(by: disposeBag)
    }
}

//MARK: - Setup VM
extension ICChatListViewModel {
    
    private func updateCellVmModel(channel: ICChannel?) {
        for vm in cellVMs {
            if vm.model?.id ?? "" == channel?.id {
                vm.model = channel
            }
        }
    }
    
}
