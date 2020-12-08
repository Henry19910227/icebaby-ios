//
//  ICLoginAPIService.swift
//  Icebaby
//
//  Created by 廖冠翰 on 2020/11/27.
//

import UIKit
import RxSwift
import RxCocoa
import RxAlamofire
import SwiftyJSON

protocol ICLoginAPI {
    func apiUserRegister(parameter: [String: Any]?) -> Single<ICUser>
    func apiUserLogin(identifier: String, password: String) -> Single<Int>
}

class ICLoginAPIService: ICLoginAPI, APIBaseRequest, ICLoginURL, APIDataTransform {
    
    private let userManager: UserManager
    
    init(userManager: UserManager) {
        self.userManager = userManager
    }
    
    func apiUserRegister(parameter: [String: Any]?) -> Single<ICUser>  {
        return Single<ICUser>.create { [unowned self] (single) -> Disposable in
            let _ = self.sendRequest(medthod: .post, url: self.registerURL, parameter: parameter, headers: nil)
                 .map({ [unowned self] (result) -> ICUser? in
                     return self.dataDecoderTransform(ICUser.self, result.dictionaryValue["Data"] ?? JSON())
                 })
                 .subscribe(onSuccess: { (user) in
                    guard let user = user else {
                        single(.error(APIError.decodeError))
                        return
                    }
                    single(.success(user))
                 }) { (error) in
                    single(.error(error))
                 }
            return Disposables.create()
        }
    }
    
    func apiUserLogin(identifier: String, password: String) -> Single<Int> {
        return Single<Int>.create { [unowned self] (single) -> Disposable in
            let parameter: [String: Any] = ["identifier": identifier, "password": password]
            let _ = self.sendRequest(medthod: .post, url: self.loginURL, parameter: parameter, headers: nil)
                .do(onSuccess: { [unowned self] (result) in
                    self.userManager.saveToken(result["token"].string ?? "")
                })
                .map({ (result) -> Int in
                    return result.dictionaryValue["data"]?.int ?? 0
                })
                .do(onSuccess: { [unowned self] (uid) in
                    self.userManager.saveUID(uid)
                })
                .subscribe(onSuccess: { (uid) in
                    single(.success(uid))
                }) { (error) in
                    single(.error(error))
                }
            return Disposables.create()
        }
    }
}
