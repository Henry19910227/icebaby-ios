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
    
    func toRoot() {
        let vc = storyboard?.instantiateViewController(withIdentifier: String(describing: ICLobbyViewController.self)) as! ICLobbyViewController
        vc.viewModel = ICLobbyViewModel(navigator: self)
        navigationController?.pushViewController(vc, animated: true)
    }
}
