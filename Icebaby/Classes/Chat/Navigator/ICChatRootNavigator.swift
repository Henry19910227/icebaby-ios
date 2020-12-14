//
//  ICChatRootNavigator.swift
//  Icebaby
//
//  Created by Henry.Liao on 2020/12/3.
//

import UIKit

class ICChatRootNavigator: ICRootNavigator {
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

extension ICChatRootNavigator {
    public func toChat(channelID: String) {
        let vc = storyboard?.instantiateViewController(identifier: String(describing:ICChatViewController.self)) as! ICChatViewController
        navigationController?.pushViewController(vc, animated: true)
    }
}
