//
//  ICLoginNavigator.swift
//  Icebaby
//
//  Created by 廖冠翰 on 2020/11/27.
//

import UIKit

class ICLoginRootNavigator {
    weak var storyboard: UIStoryboard?
    weak var navigationController: UINavigationController?
    weak var window: UIWindow?
    
    init(_ window: UIWindow?, _ navigationController: UINavigationController?, _ storyboard: UIStoryboard?) {
        self.navigationController = navigationController
        self.storyboard = storyboard
        self.window = window
    }
}

extension ICLoginRootNavigator: ICRootNavigator {
    func toRoot() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "ICLoginViewController") as! ICLoginViewController
        vc.viewModel = ICLoginViewModel(navigator: self, loginAPIService: ICLoginAPIService())
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func presendToMain() {
        let mainTabBarController = ICMainTabBarController()
        mainTabBarController.modalPresentationStyle = .fullScreen
        mainTabBarController.modalTransitionStyle = .flipHorizontal
        ICMainTabBarNavigator(window,mainTabBarController).toMain()
        navigationController?.present(mainTabBarController, animated: true, completion: nil)
    }
}
