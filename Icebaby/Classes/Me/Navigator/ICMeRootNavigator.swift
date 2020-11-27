//
//  ICMeRootNavigator.swift
//  Icebaby
//
//  Created by Henry.Liao on 2020/11/27.
//

import UIKit

class ICMeRootNavigator: ICRootNavigator {

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
        let vc = storyboard?.instantiateViewController(withIdentifier: String(describing: ICMeViewController.self)) as! ICMeViewController
        navigationController?.pushViewController(vc, animated: true)
    }
}
