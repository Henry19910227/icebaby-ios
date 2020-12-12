//
//  ICAppNavigator.swift
//  Icebaby
//
//  Created by 廖冠翰 on 2020/11/27.
//

import UIKit

class ICApplicationNavigator: ICAppNavigator {
    var storyboard: UIStoryboard?
    var navigationController = UINavigationController()
    var window: UIWindow
    var loginRootNavigator: ICLoginRootNavigator?
    @discardableResult required init(window: UIWindow) {
        self.window = window
        commonInit()
        toLogin()
    }
    
    private func commonInit() {
        let loginStoryboard = UIStoryboard(name: "Login", bundle: nil)
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        loginRootNavigator = ICLoginRootNavigator(window, navigationController, loginStoryboard, mainStoryboard)
    }
    
    private func toLogin() {
        window.rootViewController = navigationController
        loginRootNavigator?.toRoot()
    }
}
