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
    
    required init(_ window: UIWindow?,
                  _ navigationController: UINavigationController?,
                  _ storyboard: UIStoryboard?) {
        self.navigationController = navigationController
        self.storyboard = storyboard
        self.window = window
    }
}

extension ICUserNavigator {
    public func toChat(channelID: Int) {
        let vc = UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(identifier: String(describing:ICChatViewController.self)) as! ICChatViewController
        navigationController?.pushViewController(vc, animated: true)
    }
}
