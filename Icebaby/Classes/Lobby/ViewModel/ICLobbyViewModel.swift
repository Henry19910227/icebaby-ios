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
    
    
    //Subject
    private let showLoadingSubject = PublishSubject<Bool>()
    private let showErrorMsgSubject = PublishSubject<String>()
    private let itemsSubject = PublishSubject<[ICLobbyCellViewModel]>()
    
    struct Input {
        public let trigger: Driver<Void>
    }
    
    struct Output {
        public let showLoading: Driver<Bool>
        public let showErrorMsg: Driver<String>
        public let items: Driver<[ICLobbyCellViewModel]>
    }

    init(navigator: ICLobbyRootNavigator, lobbyAPIService: ICLobbyAPI) {
        self.navigator = navigator
        self.lobbyAPIService = lobbyAPIService
    }
}

// MARK: - Transform
extension ICLobbyViewModel {
    @discardableResult func transform(input: Input) -> Output {
        bindTrigger(trigger: input.trigger)
        return Output(showLoading: showLoadingSubject.asDriver(onErrorJustReturn: false),
                      showErrorMsg: showErrorMsgSubject.asDriver(onErrorJustReturn: ""),
                      items: itemsSubject.asDriver(onErrorJustReturn: []))
    }
}

// MARK: - Bind
extension ICLobbyViewModel {
    private func bindTrigger(trigger: Driver<Void>) {
        trigger
            .do(onNext: { [unowned self] (_) in
                self.apiGetUserList()
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


