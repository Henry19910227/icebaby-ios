//
//  ICMeAPIService.swift
//  Icebaby
//
//  Created by Henry.Liao on 2021/4/16.
//

import UIKit
import RxSwift
import RxCocoa
import RxAlamofire
import SwiftyJSON
import Alamofire

protocol ICMeAPI {
    func apiLogout() -> Single<Void>
}

class ICMeAPIService: ICMeAPI {
    func apiLogout() -> Single<Void> {
        return Single<Void>.create { (single) -> Disposable in
            return Disposables.create()
        }
    }
}
