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
    
    // storyboard
    private let lobbyStoryboard = UIStoryboard(name: "Lobby", bundle: nil)
    private let meStoryboard = UIStoryboard(name: "Me", bundle: nil)
    
    
    // navigation
    private lazy var lobbyNav: UINavigationController = {
         let lobbyNav = UINavigationController()
         lobbyNav.title = "大廳"
         return lobbyNav
    }()
    private lazy var meNav: UINavigationController = {
         let meNav = UINavigationController()
         meNav.title = "我的"
         return meNav
    }()
    
    
    init(_ window: UIWindow?, _ tabBarController: UITabBarController) {
        self.tabBarController = tabBarController
        self.window = window
        self.commonInit()
    }
    
    private func commonInit() {
        self.tabBarController.viewControllers = [lobbyNav, meNav]
    }
    
    func toMain() {
        ICLobbyRootNavigator(window, lobbyNav, lobbyStoryboard).toRoot()
        ICMeRootNavigator(window, meNav, meStoryboard).toRoot()
    }

}
