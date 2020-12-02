//
//  ICLobbyAPIService.swift
//  Icebaby
//
//  Created by Henry.Liao on 2020/12/2.
//

import UIKit
import RxSwift
import RxCocoa
import RxAlamofire
import SwiftyJSON

protocol ICLobbyAPI {
    func apiGetUserList() -> Single<[ICUser]>
    func apiGetUserDetail(userID: Int) -> Single<ICUserDetail?>
}

class ICLobbyAPIService: APIRequest, APIToken, APIDataTransform, ICLobbyAPI, ICLobbyURL {
    func apiGetUserList() -> Single<[ICUser]> {
        return Single<[ICUser]>.create { (single) -> Disposable in
            let parameter: [String: Any] = ["role": 2]
            let _ = self.apiRequest(medthod: .get, url: self.usersURL, parameter: parameter)
                .map({ (result) -> [ICUser] in
                    let data = result.dictionary?["data"]?.array ?? []
                    return self.dataDecoderArrayTransform(ICUser.self, data)
                }).subscribe { (users) in
                    single(.success(users))
                } onError: { (error) in
                    single(.error(error))
                }
            return Disposables.create()
        }
    }
    
    func apiGetUserDetail(userID: Int) -> Single<ICUserDetail?> {
        return Single<ICUserDetail?>.create { (single) -> Disposable in
            let url = self.userDetailURL(userID: userID)
            let _ = self.apiRequest(medthod: .get, url: url, parameter: nil)
                .map({ (result) -> ICUserDetail? in
                    return self.dataDecoderTransform(ICUserDetail.self, result.dictionaryValue["data"] ?? JSON())
                }).subscribe { (userDetail) in
                    single(.success(userDetail))
                } onError: { (error) in
                    single(.error(error))
                }
            return Disposables.create()
        }
    }
}
