//
//  ICChatListViewController.swift
//  Icebaby
//
//  Created by Henry.Liao on 2020/12/3.
//

import UIKit
import RxCocoa
import RxSwift


class ICChatListViewController: ICBaseViewController {

    // Public
    public var viewModel: ICChatListViewModel?
    
    // Rx
    private let disposeBag = DisposeBag()
    

}

//MARK: - Life Cycle
extension ICChatListViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
    }
}

extension ICChatListViewController {
    func bindViewModel() {
        let chatTrigger = NotificationCenter
                    .default
                    .rx
                    .notification(Notification.Name(rawValue: "StartNewChat"))
                    .takeUntil(self.rx.deallocated)
                    .map({ (notification) -> [String: Any] in
                        return notification.userInfo as? [String: Any] ?? [:]
                    })
                    .asDriver(onErrorJustReturn: [:])
        let input = ICChatListViewModel.Input(chatTrigger: chatTrigger)
        viewModel?.transform(input: input)

    }
}