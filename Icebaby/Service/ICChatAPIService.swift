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
    func apiGetMyChannels() -> Single<[ICChannel]>
    func apiUpdateReadDate(channelID: String, userID: Int, date: String) -> Single<ICMember?>
    func apiHistory(channelID: String, offset: Int, count: Int) -> Single<[ICChatData]>
    func apiGetChannel(guestID: Int) -> Single<ICChannel?>
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
    
    func apiGetMyChannels() -> Single<[ICChannel]> {
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
    
    func apiUpdateReadDate(channelID: String, userID: Int, date: String) -> Single<ICMember?> {
        let header = HTTPHeaders(["token": self.userManager.token() ?? ""])
        let parameter: [String: Any] = ["user_id": userID, "read_at": date]
        return Single<ICMember?>.create { [unowned self] (single) -> Disposable in
            let _ = self.sendRequest(medthod: .patch,
                                     url: self.updateReadDateURL(channelID: channelID),
                                     parameter: parameter,
                                     headers: header)
                .map ({ (result) -> ICMember? in
                    let data = result.dictionary?["data"] ?? JSON()
                    return self.dataDecoderTransform(ICMember.self, data)
                })
                .subscribe(onSuccess: { (member) in
                    single(.success(member))
                }, onError: { (error) in
                    single(.error(error))
                })
            return Disposables.create()
        }
    }
    
    func apiHistory(channelID: String, offset: Int, count: Int) -> Single<[ICChatData]> {
        let header = HTTPHeaders(["token": self.userManager.token() ?? ""])
        let parameter: [String: Any] = ["offset": offset, "count": count]
        return Single<[ICChatData]>.create { [unowned self] (single) -> Disposable in
            let _ = self.sendRequest(medthod: .get,
                             url: self.historyURL(channelID: channelID),
                             parameter: parameter,
                             headers: header)
                .map ({ (result) -> [ICChatData] in
                    var data = result.dictionary?["data"]?.array ?? []
                    data.reverse()
                    return self.dataDecoderArrayTransform(ICChatData.self, data)
                }).subscribe { (datas) in
                    single(.success(datas))
                } onError: { (error) in
                    single(.error(error))
                }
            return Disposables.create()
        }
    }
    
    func apiGetChannel(guestID: Int) -> Single<ICChannel?> {
        return Single<ICChannel?>.create { [unowned self] (single) -> Disposable in
            let header = HTTPHeaders(["token": self.userManager.token() ?? ""])
            let parameter: [String: Any] = ["guest_id": guestID]
            let _ = self.sendRequest(medthod: .get,
                             url: self.getChannel,
                             parameter: parameter,
                             headers: header)
                .map ({ [unowned self] (result) -> ICChannel? in
                    let data = result.dictionary?["data"] ?? JSON()
                    return self.dataDecoderTransform(ICChannel.self, data)
                }).subscribe { (channel) in
                    single(.success(channel))
                } onError: { (error) in
                    single(.error(error))
                }
            return Disposables.create()
        }
    }
}
