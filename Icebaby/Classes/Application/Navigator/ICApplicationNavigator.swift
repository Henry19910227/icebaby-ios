//
//  ICAppNavigator.swift
//  Icebaby
//
//  Created by 廖冠翰 on 2020/11/27.
//

import UIKit

class ICApplicationNavigator: ICAppNavigator {
    var storyboard: UIStoryboard?
    var navigationController: UINavigationController?
    var window: UIWindow
    @discardableResult required init(window: UIWindow) {
        self.window = window
        toLogin()
    }
    
    private func toLogin() {
        let loginStoryboard = UIStoryboard(name: "Login", bundle: nil)
        let loginNav = UINavigationController()
        window.rootViewController = loginNav
        ICLoginRootNavigator(window, loginNav, loginStoryboard).toRoot()
    }
}
