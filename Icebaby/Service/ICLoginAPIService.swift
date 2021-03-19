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
    func apiUserLogin(identifier: String, password: String) -> Single<(Int, String, String)>
}

class ICLoginAPIService: ICLoginAPI, APIBaseRequest, ICLoginURL, APIDataTransform {
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
    
    func apiUserLogin(identifier: String, password: String) -> Single<(Int, String, String)> {
        return Single<(Int, String, String)>.create { [unowned self] (single) -> Disposable in
            let parameter: [String: Any] = ["mobile": identifier, "password": password]
            let _ = self.sendRequest(medthod: .post, url: self.loginURL, parameter: parameter, headers: nil)
                .map({ (result) -> (Int, String, String) in
                    let uid = result.dictionaryValue["data"]?.dictionaryValue["id"]?.int ?? 0
                    let token = result["token"].string ?? ""
                    let nickname = result.dictionaryValue["data"]?
                        .dictionaryValue["info"]?
                        .dictionaryValue["nickname"]?
                        .string ?? ""
                    return (uid, token, nickname)
                })
                .subscribe(onSuccess: { (uid, token, nickname) in
                    single(.success((uid, token, nickname)))
                }) { (error) in
                    single(.error(error))
                }
            return Disposables.create()
        }
    }
}
