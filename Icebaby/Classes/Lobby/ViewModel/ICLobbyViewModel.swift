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
    
    //DI Param
    private let navigator: ICLobbyRootNavigator?
    
    struct Input {
        public let trigger: Driver<Void>
    }
    
    struct Output {
        
    }

    init(navigator: ICLobbyRootNavigator) {
        self.navigator = navigator
    }
}

// MARK: - Transform
extension ICLobbyViewModel {
    @discardableResult func transform(input: Input) -> Output {
        bindTrigger(trigger: input.trigger)
        return Output()
    }
}

// MARK: - Bind
extension ICLobbyViewModel {
    private func bindTrigger(trigger: Driver<Void>) {
        trigger
            .do(onNext: { (_) in
                
            })
            .drive()
            .disposed(by: disposeBag)
    }
}

// MARK: - API
extension ICLobbyViewModel {
    
}


