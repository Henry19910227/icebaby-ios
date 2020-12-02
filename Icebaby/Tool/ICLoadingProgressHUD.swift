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
    
    init() {
        hud.position = .center
    }
    
    func show(_ view: UIView) {
        hud.show(in: view)
    }
    
    func hide() {
        hud.dismiss(animated: true)
    }
}
