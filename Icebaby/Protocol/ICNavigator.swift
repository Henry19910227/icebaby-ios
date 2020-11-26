//
//  ICNavigator.swift
//  Icebaby
//
//  Created by 廖冠翰 on 2020/11/26.
//

import UIKit

protocol ICAppNavigator {
    init(window: UIWindow)
}

protocol ICMainNavigator {
    func toMain()
}

protocol ICRootNavigator {
    func toRoot()
}

protocol ICNavigator {}
