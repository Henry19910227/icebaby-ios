//
//  ICChatAPIService.swift
//  Icebaby
//
//  Created by Henry.Liao on 2020/12/3.
//

import UIKit
import RxSwift
import RxCocoa
import RxAlamofire
import SwiftyJSON
import Alamofire

protocol ICChatAPI {
    func apiNewChat(guestID: Int) -> Single<Int?>
}

class ICChatAPIService: APIBaseRequest, APIDataTransform, ICChatAPI, ICChatURL {

    private let userManager: UserManager
    
    init(userManager: UserManager) {
        self.userManager = userManager
    }
    
    func apiNewChat(guestID: Int) -> Single<Int?> {
        return Single<Int?>.create { [unowned self] (single) -> Disposable in
            let header = HTTPHeaders(["token": self.userManager.token() ?? ""])
            let parameter: [String: Any] = ["guest_id": guestID]
            let _ = self.sendRequest(medthod: .post, url: self.newChatURL, parameter: parameter, headers: header)
                .map({ (result) -> Int? in
                    return result.dictionaryValue["data"]?.int
                })
                .subscribe(onSuccess: { (channelID) in
                    single(.success(channelID))
                }, onError: { (error) in
                    single(.error(error))
                })
            return Disposables.create()
        }
    }
}
