//
//  ICLobbyRootNavigator.swift
//  Icebaby
//
//  Created by Henry.Liao on 2020/12/2.
//

import UIKit

class ICLobbyRootNavigator: ICRootNavigator {

    weak var window: UIWindow?
    weak var storyboard: UIStoryboard?
    weak var navigationController: UINavigationController?
    weak var mainNavigator: ICMainTabBarNavigator?
    
    required init(_ window: UIWindow?,
                  _ navigationController: UINavigationController?,
                  _ storyboard: UIStoryboard?,
                  _ mainNavigator: ICMainTabBarNavigator?) {
        self.navigationController = navigationController
        self.storyboard = storyboard
        self.window = window
        self.mainNavigator = mainNavigator
    }
}

extension ICLobbyRootNavigator {
    func toRoot() {
        let vc = storyboard?.instantiateViewController(withIdentifier: String(describing: ICLobbyViewController.self)) as! ICLobbyViewController
        vc.viewModel = ICLobbyViewModel(navigator: self, lobbyAPIService: ICLobbyAPIService())
        navigationController?.setViewControllers([vc], animated: true)
//        navigationController?.pushViewController(vc, animated: true)
    }
    
    func toUser(userID: Int) {
        let navigator = ICUserNavigator(window, navigationController, storyboard, mainNavigator)
        let vc = storyboard?.instantiateViewController(withIdentifier: String(describing: ICUserViewController.self)) as! ICUserViewController
        vc.viewModel = ICUserViewModel(navigator: navigator, lobbyAPIService: ICLobbyAPIService(), userID: userID)
        navigationController?.pushViewController(vc, animated: true)
    }
}
