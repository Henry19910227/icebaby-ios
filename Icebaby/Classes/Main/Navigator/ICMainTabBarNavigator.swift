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
    private let chatStoryboard = UIStoryboard(name: "Chat", bundle: nil)
    private let meStoryboard = UIStoryboard(name: "Me", bundle: nil)
    
    
    // navigation
    private lazy var lobbyNav: UINavigationController = {
         let lobbyNav = UINavigationController()
         lobbyNav.title = "大廳"
         return lobbyNav
    }()
    private lazy var chatNav: UINavigationController = {
         let chatNav = UINavigationController()
         chatNav.title = "聊天"
         return chatNav
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
        self.tabBarController.viewControllers = [lobbyNav, chatNav, meNav]
    }
    
}

extension ICMainTabBarNavigator {
    func toMain() {
        ICLobbyRootNavigator(window, lobbyNav, lobbyStoryboard, self).toRoot()
        ICChatRootNavigator(window, chatNav, chatStoryboard).toRoot()
        ICMeRootNavigator(window, meNav, meStoryboard).toRoot()
    }
    
    func selectedIndex(_ index: Int) {
        self.tabBarController.selectedIndex = index
    }
}
