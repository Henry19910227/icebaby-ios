//
//  ICMainTabBarNavigator.swift
//  Icebaby
//
//  Created by Henry.Liao on 2020/11/27.
//

import UIKit

class ICMainTabBarNavigator: ICMainNavigator {
    
    weak var window: UIWindow?
    private let tabBarController: UITabBarController
    
    private let meStoryboard = UIStoryboard(name: "Me", bundle: nil)
    
    private lazy var meNav: UINavigationController = {
         let meNav = UINavigationController()
         return meNav
    }()
    
    init(_ window: UIWindow?, _ tabBarController: UITabBarController) {
        self.tabBarController = tabBarController
        self.window = window
        self.commonInit()
    }
    
    private func commonInit() {
        self.tabBarController.viewControllers = [meNav]
    }
    
    func toMain() {
        ICMeRootNavigator(window, meNav, meStoryboard).toRoot()
    }

}
