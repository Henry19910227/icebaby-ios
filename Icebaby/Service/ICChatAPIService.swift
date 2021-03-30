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
    func apiCreateChannel(friendID: Int) -> Single<String?>
    func apiActivateChannel(channelID: String) -> Single<String?>
    func apiShutdownChannel(channelID: String) -> Single<String?>
    func apiGetChannels(userID: Int) -> Single<[ICChannel]>
    func apiUpdateReadDate(channelID: String, userID: Int, date: String) -> Single<ICMember?>
    func apiHistory(channelID: String, offset: Int, count: Int) -> Single<[ICChatData]>
    func apiHistories(channelIDs: [String], page: Int, size: Int) -> Single<JSON>
    func apiGetChannel(reciverID: Int) -> Single<ICChannel?>
}

class ICChatAPIService: APIBaseRequest, APIDataTransform, ICChatAPI, ICChatURL {

    private let userManager: UserManager
    
    init(userManager: UserManager) {
        self.userManager = userManager
    }
    
    func apiCreateChannel(friendID: Int) -> Single<String?> {
        return Single<String?>.create { [unowned self] (single) -> Disposable in
            let header = HTTPHeaders(["token": self.userManager.token() ?? ""])
            let parameter: [String: Any] = ["friend_id": friendID]
            let _ = self.sendRequest(medthod: .post, url: self.newChatURL, parameter: parameter, headers: header)
                .map({ (result) -> String? in
                    return result.dictionaryValue["data"]?.dictionaryValue["channel_id"]?.string
                })
                .subscribe(onSuccess: { (channelID) in
                    single(.success(channelID))
                }, onError: { (error) in
                    single(.error(error))
                })
            return Disposables.create()
        }
    }
    
    func apiActivateChannel(channelID: String) -> Single<String?> {
        return Single<String?>.create { [unowned self] (single) -> Disposable in
            let header = HTTPHeaders(["token": self.userManager.token() ?? ""])
            let parameter: [String: Any] = ["channel_id": channelID]
            let _ = self.sendRequest(medthod: .post, url: self.activateChatURL(channelID: channelID), parameter: parameter, headers: header)
                .map({ (result) -> String? in
                    return result.dictionaryValue["data"]?.dictionaryValue["channel_id"]?.string
                })
                .subscribe(onSuccess: { (channelID) in
                    single(.success(channelID))
                }, onError: { (error) in
                    single(.error(error))
                })
            return Disposables.create()
        }
    }
    
    func apiShutdownChannel(channelID: String) -> Single<String?> {
        return Single<String?>.create { [unowned self] (single) -> Disposable in
            let header = HTTPHeaders(["token": self.userManager.token() ?? ""])
            let parameter: [String: Any] = ["channel_id": channelID]
            let _ = self.sendRequest(medthod: .post, url: self.shutdownChatURL(channelID: channelID), parameter: parameter, headers: header)
                .map({ (result) -> String? in
                    return result.dictionaryValue["data"]?.dictionaryValue["channel_id"]?.string
                })
                .subscribe(onSuccess: { (channelID) in
                    single(.success(channelID))
                }, onError: { (error) in
                    single(.error(error))
                })
            return Disposables.create()
        }
    }
    
    func apiGetChannels(userID: Int) -> Single<[ICChannel]> {
        let header = HTTPHeaders(["token": self.userManager.token() ?? ""])
        let parameter: [String: Any] = ["user_id": userID, "status": 1]
        return Single<[ICChannel]>.create { [unowned self] (single) -> Disposable in
            let _ = self.sendRequest(medthod: .get, url: self.myChannelsURL, parameter: parameter, headers: header)
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
            let _ = self.sendRequest(medthod: .put,
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
    
    func apiHistories(channelIDs: [String], page: Int, size: Int) -> Single<JSON> {
        let header = HTTPHeaders(["Token": self.userManager.token() ?? ""])
        let parameter: [String: Any] = ["channel_ids": channelIDs, "page": page, "size": size]
        return Single<JSON>.create { [unowned self] (single) -> Disposable in
            let _ = self.sendRequest(medthod: .post,
                             url: URL(fileURLWithPath: ""),
                             parameter: parameter,
                             headers: header)
                .map ({ (result) -> JSON in
                    return result
                }).subscribe { (datas) in
                    single(.success(datas))
                } onError: { (error) in
                    single(.error(error))
                }
            return Disposables.create()
        }
    }
    
    func apiGetChannel(reciverID: Int) -> Single<ICChannel?> {
        return Single<ICChannel?>.create { [unowned self] (single) -> Disposable in
            let header = HTTPHeaders(["token": self.userManager.token() ?? ""])
            let parameter: [String: Any] = ["reciver_id": reciverID]
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
