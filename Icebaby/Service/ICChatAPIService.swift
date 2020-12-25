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
    func apiNewChat(guestID: Int) -> Single<String?>
    func apiGetMyChannel() -> Single<[ICChannel]>
    func apiUpdateReadDate(channelID: String, userID: Int, date: Date) -> Single<ICMember?>
}

class ICChatAPIService: APIBaseRequest, APIDataTransform, ICChatAPI, ICChatURL {

    private let userManager: UserManager
    
    init(userManager: UserManager) {
        self.userManager = userManager
    }
    
    func apiNewChat(guestID: Int) -> Single<String?> {
        return Single<String?>.create { [unowned self] (single) -> Disposable in
            let header = HTTPHeaders(["token": self.userManager.token() ?? ""])
            let parameter: [String: Any] = ["guest_id": guestID]
            let _ = self.sendRequest(medthod: .post, url: self.newChatURL, parameter: parameter, headers: header)
                .map({ (result) -> String? in
                    return result.dictionaryValue["data"]?.string
                })
                .subscribe(onSuccess: { (channelID) in
                    single(.success(channelID))
                }, onError: { (error) in
                    single(.error(error))
                })
            return Disposables.create()
        }
    }
    
    func apiGetMyChannel() -> Single<[ICChannel]> {
        let header = HTTPHeaders(["token": self.userManager.token() ?? ""])
        return Single<[ICChannel]>.create { [unowned self] (single) -> Disposable in
            let _ = self.sendRequest(medthod: .get, url: self.myChannelsURL, parameter: nil, headers: header)
                .map ({ (result) -> [ICChannel] in
                    let data = result.dictionary?["data"]?.array ?? []
                    return self.dataDecoderArrayTransform(ICChannel.self, data)
                })
                .subscribe(onSuccess: { (channels) in
                    single(.success(channels))
                }, onError: { (error) in
                    single(.error(error))
                })
            return Disposables.create()
        }
    }
    
    func apiUpdateReadDate(channelID: String, userID: Int, date: Date) -> Single<ICMember?> {
        let header = HTTPHeaders(["token": self.userManager.token() ?? ""])
        let parameter: [String: Any] = ["channel_id": channelID, "user_id": userID]
        return Single<ICMember?>.create { [unowned self] (single) -> Disposable in
            let _ = self.sendRequest(medthod: .get,
                                     url: self.updateMemberURL,
                                     parameter: parameter,
                                     headers: header)
                .map ({ (result) -> ICMember? in
                    let data = result.dictionary?["data"] ?? JSON()
                    return self.dataDecoderTransform(ICMember.self, data)
                })
                .subscribe(onSuccess: { (channels) in
                    single(.success(channels))
                }, onError: { (error) in
                    single(.error(error))
                })
            return Disposables.create()
        }
    }
}
