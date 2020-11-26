//
//  ICLoginNavigator.swift
//  Icebaby
//
//  Created by 廖冠翰 on 2020/11/27.
//

import UIKit

class ICLoginNavigator {
    weak var storyboard: UIStoryboard?
    weak var navigationController: UINavigationController?
    weak var window: UIWindow?
    
    init(_ window: UIWindow?, _ navigationController: UINavigationController?, _ storyboard: UIStoryboard?) {
        self.navigationController = navigationController
        self.storyboard = storyboard
        self.window = window
    }
}

extension ICLoginNavigator: ICRootNavigator {
    func toRoot() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "ICLoginViewController") as! ICLoginViewController
        navigationController?.pushViewController(vc, animated: true)
    }
}
