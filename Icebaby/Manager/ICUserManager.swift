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
    func saveMobile(_ mobile: String)
    func token() -> String?
    func uid() -> Int
    func nickname() -> String
    func mobile() -> String
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
    
    func saveMobile(_ mobile: String) {
        UserDefaults.standard.set(mobile, forKey: "Mobile")
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
    
    func mobile() -> String {
        return UserDefaults.standard.value(forKey: "Mobile") as? String ?? ""
    }
    
    func clearToken() {
        UserDefaults.standard.set(nil, forKey: "APIToken")
    }
    
    func clearUID() {
        UserDefaults.standard.set(nil, forKey: "UID")
    }
}
