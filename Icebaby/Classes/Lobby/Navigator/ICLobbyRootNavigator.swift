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
    
    required init(_ window: UIWindow?,
                  _ navigationController: UINavigationController?,
                  _ storyboard: UIStoryboard?) {
        self.navigationController = navigationController
        self.storyboard = storyboard
        self.window = window
    }
}

extension ICLobbyRootNavigator {
    func toUser(userID: Int) {
        let navigator = ICUserNavigator(window, navigationController, storyboard)
        let lobbyAPIService = ICLobbyAPIService(userManager: ICUserManager())
        let chatAPIService = ICChatAPIService(userManager: ICUserManager())
        let vc = storyboard?.instantiateViewController(withIdentifier: String(describing: ICUserViewController.self)) as! ICUserViewController
        vc.viewModel = ICUserViewModel(navigator: navigator,
                                       lobbyAPIService: lobbyAPIService,
                                       chatAPIService: chatAPIService,
                                       chatManager: ICChatManager.shard,
                                       userID: userID)
        navigationController?.pushViewController(vc, animated: true)
    }
}
