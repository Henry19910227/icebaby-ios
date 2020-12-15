//
//  ICChatNavigator.swift
//  Icebaby
//
//  Created by Henry.Liao on 2020/12/15.
//

import UIKit

class ICChatNavigator: ICNavigator {
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
