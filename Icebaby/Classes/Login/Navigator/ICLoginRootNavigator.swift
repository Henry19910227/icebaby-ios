//
//  ICLoginNavigator.swift
//  Icebaby
//
//  Created by 廖冠翰 on 2020/11/27.
//

import UIKit

class ICLoginRootNavigator {
    private var loginStoryboard: UIStoryboard?
    private var mainStoryboard: UIStoryboard?
    weak var navigationController: UINavigationController?
    weak var window: UIWindow?
    
    private var tabbarVC: ICMainTabBarController?
    
    init(_ window: UIWindow?,
         _ navigationController: UINavigationController?,
         _ loginStoryboard: UIStoryboard?, _ mainStoryboard: UIStoryboard?) {
        self.navigationController = navigationController
        self.loginStoryboard = loginStoryboard
        self.mainStoryboard = mainStoryboard
        self.window = window
    }
}

extension ICLoginRootNavigator: ICRootNavigator {
    func toRoot() {
        let vc = loginStoryboard?.instantiateViewController(withIdentifier: "ICLoginViewController") as! ICLoginViewController
        vc.viewModel = ICLoginViewModel(navigator: self, loginAPIService: ICLoginAPIService())
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func presendToMain() {
        let navigator = ICMainTabBarNavigator(window)
        let tabbarVC = mainStoryboard?.instantiateViewController(withIdentifier: "ICMainTabBarController") as! ICMainTabBarController
        tabbarVC.modalPresentationStyle = .fullScreen
        tabbarVC.modalTransitionStyle = .flipHorizontal
        tabbarVC.viewModel = ICMainTabBarViewModel(navigator: navigator, chatManager: ICChatManager.shard)
        navigationController?.present(tabbarVC, animated: true, completion: nil)
    }
}
