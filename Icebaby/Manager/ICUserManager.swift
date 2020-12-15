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
    func saveNickname(_ nickname: String)
    func token() -> String?
    func uid() -> Int
    func nickname() -> String
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
    
    func saveNickname(_ nickname: String) {
        UserDefaults.standard.set(nickname, forKey: "Nickname")
    }
    
    func token() -> String? {
        return UserDefaults.standard.value(forKey: "APIToken") as? String
    }
    
    func uid() -> Int {
        return UserDefaults.standard.value(forKey: "UID") as? Int ?? 0
    }
    
    func nickname() -> String {
        return UserDefaults.standard.value(forKey: "Nickname") as? String ?? ""
    }
    
    func clearToken() {
        UserDefaults.standard.set(nil, forKey: "APIToken")
    }
    
    func clearUID() {
        UserDefaults.standard.set(nil, forKey: "UID")
    }
}
