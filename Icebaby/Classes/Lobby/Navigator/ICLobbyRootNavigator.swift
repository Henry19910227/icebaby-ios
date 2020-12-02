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
    func toRoot() {
        let vc = storyboard?.instantiateViewController(withIdentifier: String(describing: ICLobbyViewController.self)) as! ICLobbyViewController
        vc.viewModel = ICLobbyViewModel(navigator: self, lobbyAPIService: ICLobbyAPIService())
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func toUser(userID: Int) {
        let vc = storyboard?.instantiateViewController(withIdentifier: String(describing: ICUserViewController.self)) as! ICUserViewController
        vc.viewModel = ICUserViewModel(navigator: self, lobbyAPIService: ICLobbyAPIService(), userID: userID)
        navigationController?.pushViewController(vc, animated: true)
    }
}
