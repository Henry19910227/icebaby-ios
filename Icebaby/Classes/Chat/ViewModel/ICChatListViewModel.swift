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
    
    //RX
    private let disposeBag = DisposeBag()
    
    //Dependency Injection
    private let navigator: ICChatRootNavigator?
    private let chatAPIService: ICChatAPI?
    
    struct Input {
    }
    
    struct Output {
    }
    
    init(navigator: ICChatRootNavigator, chatAPIService: ICChatAPI) {
        self.navigator = navigator
        self.chatAPIService = chatAPIService
    }
}

extension ICChatListViewModel {
    @discardableResult func transform(input: Input) -> Output {
        return Output()
    }
}
