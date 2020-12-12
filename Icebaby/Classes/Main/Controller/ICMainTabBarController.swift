//
//  ICMainTabBarController.swift
//  Icebaby
//
//  Created by Henry.Liao on 2020/11/27.
//

import UIKit
import RxCocoa
import RxSwift

class ICMainTabBarController: UITabBarController {
    public var viewModel: ICMainTabBarViewModel?
    private var trigger = PublishSubject<UITabBarController>()
    
}

//MARK: - Life Cycle
extension ICMainTabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
        trigger.onNext(self)
    }
}

//MARK: - Bind
extension ICMainTabBarController {
    private func bindViewModel() {
        let input = ICMainTabBarViewModel.Input(trigger: trigger.asDriver(onErrorJustReturn: UITabBarController()))
        viewModel?.transform(input: input)
    }
}
