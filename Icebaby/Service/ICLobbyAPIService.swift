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
}

class ICLobbyAPIService: ICLobbyAPI {
    func apiGetUserList() -> Single<[ICUser]> {
        return Single<[ICUser]>.create { (single) -> Disposable in
            return Disposables.create()
        }
    }
}
