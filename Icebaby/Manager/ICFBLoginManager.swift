//
//  ICFBLoginManager.swift
//  Icebaby
//
//  Created by 廖冠翰 on 2021/2/13.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import RxSwift
import RxCocoa

protocol FBLoginManager {
    func login() -> Driver<[String:Any]>
}

class ICFBLoginManager: FBLoginManager {
    
    private let loginManager = LoginManager()
    private weak var target: UIViewController?
    private var graphRequest:GraphRequest?
    
    init(target: UIViewController) {
        self.target = target
    }
    
    public func login() -> Driver<[String:Any]> {
         return startFbLogin(target: target ?? UIViewController())
                     .filter({ $0 })
                     .flatMapLatest { (isSuccess) -> Observable<[String: Any]?> in
                           return self.getUserInfo()
                     }
                     .map({ (result) -> [String:Any] in
                        var dict = [String: Any]()
                        dict["id"] = result?["id"] as? String ?? ""
                        dict["name"] = result?["name"] as? String ?? ""
                        dict["email"] = result?["email"] as? String ?? ""
                        dict["token"] =  AccessToken.current?.tokenString ?? ""
                        return dict
                     })
                     .asDriver(onErrorJustReturn: [:])
    }
    
    private func startFbLogin(target: UIViewController) -> Observable<Bool> {
        return Observable<Bool>.create { [unowned self] (observer) -> Disposable in
            self.loginManager.logIn(permissions: ["email"], from: target) { (result, error) in
                guard error == nil else {
                    observer.onNext(false)
                    return
                }
                if result?.isCancelled == true {
                    observer.onNext(false)
                    return
                }
                observer.onNext(true)
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
    
    private func getUserInfo() -> Observable<[String: Any]?> {
        return Observable<[String: Any]?>.create { (observer) -> Disposable in
            GraphRequest(graphPath: "me?fields=id,name,email").start { (conn, result, error) in
                observer.onNext(result as? [String: Any])
            }
            return Disposables.create()
        }
    }
}
