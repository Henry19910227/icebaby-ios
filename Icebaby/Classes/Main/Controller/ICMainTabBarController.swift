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
    private let disposeBag = DisposeBag()
    private let hud = ICLoadingProgressHUD()
    
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
        let output = viewModel?.transform(input: input)
        
        output?
            .showLoading
            .drive(onNext: { [unowned self] (isShow) in
                if isShow {
                    self.hud.show(view)
                } else {
                    self.hud.hide()
                }
            })
            .disposed(by: disposeBag)
        
        output?
            .showErrorMsg
            .drive(onNext: { [unowned self] (msg) in
                self.hud.toast(self.view, msg)
            })
            .disposed(by: disposeBag)
    }
}
