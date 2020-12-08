//
//  ICMainTabBarNavigator.swift
//  Icebaby
//
//  Created by Henry.Liao on 2020/11/27.
//

import UIKit

class ICMainTabBarNavigator: ICMainNavigator {
    
    weak var window: UIWindow?
    
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
    
    
    init(_ window: UIWindow?) {
        self.window = window
    }
}

extension ICMainTabBarNavigator {
    func toMain(tabbarVC: UITabBarController) {
        tabbarVC.viewControllers = [lobbyNav, chatNav, meNav]
        
        // 大廳 tabbar
        let lobbyNavgator = ICLobbyRootNavigator(window, lobbyNav, lobbyStoryboard)
        let lobbyVC = lobbyStoryboard.instantiateViewController(withIdentifier: String(describing: ICLobbyViewController.self)) as! ICLobbyViewController
        lobbyVC.viewModel = ICLobbyViewModel(navigator: lobbyNavgator, lobbyAPIService: ICLobbyAPIService())
        lobbyNav.setViewControllers([lobbyVC], animated: true)
        
        // 聊天 tabbar
        let chatNavigator = ICChatRootNavigator(window, chatNav, chatStoryboard)
        let chatVC = chatStoryboard.instantiateViewController(withIdentifier: String(describing: ICChatListViewController.self)) as! ICChatListViewController
        chatVC.viewModel = ICChatListViewModel(navigator: chatNavigator, chatAPIService: ICChatAPIService())
        chatNav.setViewControllers([chatVC], animated: true)
        chatVC.loadViewIfNeeded()

        // 我的 tabbar
        let meVC = meStoryboard.instantiateViewController(withIdentifier: String(describing: ICMeViewController.self)) as! ICMeViewController
        meNav.setViewControllers([meVC], animated: true)
    }
}
