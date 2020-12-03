//
//  ICUserNavigator.swift
//  Icebaby
//
//  Created by 廖冠翰 on 2020/12/3.
//

import UIKit

class ICUserNavigator: NSObject {
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

extension ICUserNavigator {
    func switchToChat() {
        mainNavigator?.selectedIndex(1)
    }
}
