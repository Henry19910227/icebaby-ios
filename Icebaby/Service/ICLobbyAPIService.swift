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
import Alamofire

protocol ICLobbyAPI {
    func apiGetUserList() -> Single<[ICUser]>
    func apiGetUserDetail(userID: Int) -> Single<ICUserDetail?>
}

class ICLobbyAPIService: APIBaseRequest, APIDataTransform, ICLobbyAPI, ICLobbyURL {
    
    private let userManager: UserManager
    
    init(userManager: UserManager) {
        self.userManager = userManager
    }
    
    func apiGetUserList() -> Single<[ICUser]> {
        return Single<[ICUser]>.create { (single) -> Disposable in
            let header = HTTPHeaders(["token": self.userManager.token() ?? ""])
            let parameter: [String: Any] = ["role": 2]
            let _ = self.sendRequest(medthod: .get, url: self.usersURL, parameter: parameter, headers: header)
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
            let header = HTTPHeaders(["token": self.userManager.token() ?? ""])
            let _ = self.sendRequest(medthod: .get, url: url, parameter: nil, headers: header)
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
