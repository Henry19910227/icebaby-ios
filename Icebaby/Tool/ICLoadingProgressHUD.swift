//
//  CKLoadingProgressHUD.swift
//  Icebaby
//
//  Created by 廖冠翰 on 2020/12/2.
//

import UIKit
import JGProgressHUD

class ICLoadingProgressHUD: ICProgressHUD {
    private let hud = JGProgressHUD(style: .light)
    private lazy var errHud: JGProgressHUD = {
        let errHud = JGProgressHUD(style: .dark)
        errHud.indicatorView = JGProgressHUDErrorIndicatorView()
        return errHud
    }()
    
    init() {
        hud.position = .center
    }
    
    func show(_ view: UIView) {
        hud.show(in: view)
    }
    
    func hide() {
        hud.dismiss(animated: true)
    }
    
    func toast(_ view: UIView, _ msg: String) {
        errHud.textLabel.text = msg
        errHud.show(in: view)
        errHud.dismiss(afterDelay: 1.0)
    }
}
