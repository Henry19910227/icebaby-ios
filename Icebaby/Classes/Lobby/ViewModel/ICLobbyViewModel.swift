//
//  ICLobbyViewModel.swift
//  Icebaby
//
//  Created by Henry.Liao on 2020/12/2.
//

import UIKit
import RxSwift
import RxCocoa

class ICLobbyViewModel: ICViewModel {
    
    //RX
    private let disposeBag = DisposeBag()
    
    //Param
    private let navigator: ICLobbyRootNavigator?
    private let lobbyAPIService: ICLobbyAPI?
    private let userManager: UserManager?
    
    //Data
    private var users: [ICUserBrief] = []
    
    //Subject
    private let showLoadingSubject = PublishSubject<Bool>()
    private let showErrorMsgSubject = PublishSubject<String>()
    private let nicknameSubject = PublishSubject<String>()
    private let itemsSubject = PublishSubject<[ICLobbyCellViewModel]>()
    
    struct Input {
        public let trigger: Driver<Void>
        public let itemSelected: Driver<IndexPath>
    }
    
    struct Output {
        public let showLoading: Driver<Bool>
        public let showErrorMsg: Driver<String>
        public let nickname: Driver<String>
        public let items: Driver<[ICLobbyCellViewModel]>
    }

    init(navigator: ICLobbyRootNavigator, lobbyAPIService: ICLobbyAPI, userManager: UserManager) {
        self.navigator = navigator
        self.lobbyAPIService = lobbyAPIService
        self.userManager = userManager
    }
}

// MARK: - Transform
extension ICLobbyViewModel {
    @discardableResult func transform(input: Input) -> Output {
        bindTrigger(trigger: input.trigger)
        itemSelected(itemSelected: input.itemSelected)
        return Output(showLoading: showLoadingSubject.asDriver(onErrorJustReturn: false),
                      showErrorMsg: showErrorMsgSubject.asDriver(onErrorJustReturn: ""),
                      nickname: nicknameSubject.asDriver(onErrorJustReturn: ""),
                      items: itemsSubject.asDriver(onErrorJustReturn: []))
    }
}

// MARK: - Bind
extension ICLobbyViewModel {
    private func bindTrigger(trigger: Driver<Void>) {
        trigger
            .do(onNext: { [unowned self] (_) in
                self.apiGetUserList()
                self.nicknameSubject.onNext(self.userManager?.nickname() ?? "")
            })
            .drive()
            .disposed(by: disposeBag)
    }
    
    private func itemSelected(itemSelected: Driver<IndexPath>) {
        itemSelected
            .do (onNext:{ [unowned self] (indexPath) in
                self.navigator?.toUser(userID: self.users[indexPath.row].id ?? 0)
            })
            .drive()
            .disposed(by: disposeBag)
    }
}

// MARK: - API
extension ICLobbyViewModel {
    private func apiGetUserList() {
        showLoadingSubject.onNext(true)
        lobbyAPIService?
            .apiGetUserList()
            .do(onSuccess: { [unowned self] (users) in
                self.users = users
            })
            .map({ (users) -> [ICLobbyCellViewModel] in
                return users.map { (user) -> ICLobbyCellViewModel in
                    let cellVM = ICLobbyCellViewModel()
                    cellVM.model = user
                    return cellVM
                }
            })
            .subscribe(onSuccess: { [unowned self] (cellVMs) in
                self.showLoadingSubject.onNext(false)
                self.itemsSubject.onNext(cellVMs)
            },onError: { [unowned self] (error) in
                self.showLoadingSubject.onNext(false)
                guard let err = error as? ICError else { return }
                self.showErrorMsgSubject.onNext("\(err.code ?? 0) \(err.msg ?? "")")
            })
            .disposed(by: disposeBag)
    }
}


