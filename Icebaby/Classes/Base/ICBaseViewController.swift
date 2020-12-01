//
//  ICBaseViewController.swift
//  Icebaby
//
//  Created by 廖冠翰 on 2020/12/2.
//

import UIKit
import RxSwift
import RxCocoa

class ICBaseViewController: UIViewController {

    private let hud = ICLoadingProgressHUD()
    override func viewDidLoad() {
        super.viewDidLoad()

    }
}

//MARK: - Public
extension ICBaseViewController {
    public func showLoading() {
        hud.show(view)
    }
    
    public func hideLoading() {
        hud.hide()
    }
}

extension Reactive where Base: ICBaseViewController {
    internal var isShowLoading: Binder<Bool> {
        return Binder(self.base) { (vc, isShow) in
            if isShow {
                vc.showLoading()
            } else {
                vc.hideLoading()
            }
        }
    }
}
