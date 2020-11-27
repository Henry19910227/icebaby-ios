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
    func apiUserLogin(identifier: String, password: String) -> Single<ICUser>
}

class ICLoginAPIService: ICLoginAPI, APIRequest, APIToken, ICLoginURL, APIDataTransform {
    
    func apiUserRegister(parameter: [String: Any]?) -> Single<ICUser>  {
        return Single<ICUser>.create { [unowned self] (single) -> Disposable in
            let _ = self.apiRequest(medthod: .post, url: self.registerURL, parameter: parameter)
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
    
    func apiUserLogin(identifier: String, password: String) -> Single<ICUser> {
        return Single<ICUser>.create { [unowned self] (single) -> Disposable in
            let parameter: [String: Any] = ["identifier": identifier, "password": password]
            let _ = self.apiRequest(medthod: .post, url: self.loginURL, parameter: parameter)
                .do(onSuccess: { [unowned self] (result) in
                    self.saveToken(result["token"].string ?? "")
                })
                .map({ [unowned self] (result) -> ICUser? in
                    return self.dataDecoderTransform(ICUser.self, result.dictionaryValue["data"] ?? JSON())
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
}
