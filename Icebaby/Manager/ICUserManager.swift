//
//  ICUserManager.swift
//  Icebaby
//
//  Created by 廖冠翰 on 2020/12/8.
//

import UIKit

protocol UserManager {
    func saveToken(_ token: String)
    func saveUID(_ uid: Int)
    func token() -> String?
    func uid() -> Int
    func clearToken()
    func clearUID()
}

class ICUserManager: UserManager {
    
    func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: "APIToken")
    }
    
    func saveUID(_ uid: Int) {
        UserDefaults.standard.set(uid, forKey: "UID")
    }
    
    func token() -> String? {
        return UserDefaults.standard.value(forKey: "APIToken") as? String
    }
    
    func uid() -> Int {
        return UserDefaults.standard.value(forKey: "UID") as? Int ?? 0
    }
    
    func clearToken() {
        UserDefaults.standard.set(nil, forKey: "APIToken")
    }
    
    func clearUID() {
        UserDefaults.standard.set(nil, forKey: "UID")
    }
}
