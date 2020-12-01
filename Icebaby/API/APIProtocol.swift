//
//  APIProtocol.swift
//  Icebaby
//
//  Created by 廖冠翰 on 2020/11/27.
//

import Foundation
import RxSwift
import RxCocoa
import RxAlamofire
import Alamofire
import SwiftyJSON

enum APIError: Error {
    case decodeError
    case NullData
    case requestError(desc: String)
    case tokenInvalid
}

class ICError: Codable, Error {
    var code: Int?
    var msg: String?
    init(_ code: Int?, _ msg: String?) {
        self.code = code
        self.msg = msg
    }
}

protocol APIBaseRequest: APIDataTransform {
    func sendRequest(medthod: HTTPMethod, url: URL, parameter: [String: Any]?, headers: HTTPHeaders?) -> Single<JSON>
    func uploadFile(medthod: HTTPMethod, url: URL, data: Data, headers: HTTPHeaders?) -> Single<JSON>
}

protocol APIRequest: APIBaseRequest, APIToken, ICLoginURL {
    func apiRequest(medthod: HTTPMethod, url: URL, parameter: [String: Any]?) -> Single<JSON>
    func apiUploadFile(medthod: HTTPMethod, url: URL, data: Data) -> Single<JSON>
}

protocol APIDataTransform {
    func dataDecoderTransform<T: Codable>(_ type:T.Type, _ value: JSON) -> T?
    func dataDecoderArrayTransform<T: Codable>(_ type:T.Type, _ value: [JSON]) -> [T]
}

protocol APIToken {
    func saveToken(_ token: String)
    func token() -> String?
    func clearToken()
}


extension APIBaseRequest {
    func sendRequest(medthod: HTTPMethod, url: URL, parameter: [String: Any]?, headers: HTTPHeaders?) -> Single<JSON> {
        return Single<JSON>.create { (single) -> Disposable in
            AF.request(url, method: medthod, parameters: parameter, encoding: JSONEncoding.default, headers: headers)
                .responseJSON { (response) in
                    guard let value = response.value else {
                        single(.error(ICError(0, "不明的錯誤!")))
                        return
                    }
                    switch response.response?.statusCode ?? 0 {
                    case 200:
                        single(.success(JSON(value)))
                    case 400:
                        let err = self.dataDecoderTransform(ICError.self, JSON(value)) ?? ICError(0, "")
                        single(.error(err))
                    default:
                        let err = self.dataDecoderTransform(ICError.self, JSON(value)) ?? ICError(0, "")
                        single(.error(err))
                        break
                    }
                }
            return Disposables.create()
        }
    }
    
    func uploadFile(medthod: HTTPMethod, url: URL, data: Data, headers: HTTPHeaders?) -> Single<JSON> {
        return Single<JSON>.create { (single) -> Disposable in
//            upload(multipartFormData: { (multipartFormData) in
//                multipartFormData.append(data, withName: "UserPhoto", fileName: "UserPhoto.jpeg", mimeType: "image/jpeg")
//            }, to: url, method: medthod, headers: headers) { (encodingResult) in
//                switch encodingResult {
//                case .success(let upload, _, _):
//                    upload.responseJSON { response in
//                        if let value = response.result.value {
//                            single(.success(JSON(value)))
//                        } else {
//                            single(.error(APIError.decodeError))
//                        }
//                    }
//                case .failure(let error):
//                    single(.error(error))
//                }
//            }
            return Disposables.create()
        }
    }
}

extension APIRequest {
    public func apiRequest(medthod: HTTPMethod, url: URL, parameter: [String: Any]?) -> Single<JSON> {
        return Single<JSON>.create { (single) -> Disposable in
            let headers = (url != self.loginURL) ? HTTPHeaders(["token": self.token() ?? ""]) : nil
            let _ = self.sendRequest(medthod: medthod, url: url, parameter: parameter, headers: headers)
                .subscribe(onSuccess: { (result) in
                    single(.success(result))
                }) { (error) in
                    single(.error(error))
                }
            return Disposables.create()
        }
    }
    
    
    func apiUploadFile(medthod: HTTPMethod, url: URL, data: Data) -> Single<JSON> {
        let headers = (url != self.loginURL) ? HTTPHeaders(["Token": self.token() ?? ""]) : nil
        return Single<JSON>.create { (single) -> Disposable in
            let _ = self.uploadFile(medthod: medthod, url: url, data: data, headers: headers)
                .subscribe(onSuccess: { (result) in
                    switch result["Code"].intValue {
                    case 400:
                        let errorMsg = result["Message"].string ?? ""
                        single(.error(APIError.requestError(desc: errorMsg)))
                    case 403:
                        single(.error(APIError.tokenInvalid))
                    default:
                        single(.success(result))
                        break
                    }
                }) { (error) in
                    single(.error(APIError.requestError(desc: error.localizedDescription)))
                }
            return Disposables.create()
        }
    }
}

extension APIDataTransform {
    func dataDecoderTransform<T: Codable>(_ type:T.Type, _ value: JSON) -> T? {
        do {
            //轉回 Data
            let dictData = try JSONSerialization.data(withJSONObject: value.dictionaryObject ?? [String: Any](), options: .prettyPrinted)
            //將 data 轉成 model
            let model = try JSONDecoder().decode(type.self, from: dictData)
            return model
        } catch {
            print("DataDecoderTransform Error : \(error)")
            return nil
        }
    }
    
    func dataDecoderArrayTransform<T: Codable>(_ type:T.Type, _ value: [JSON]) -> [T] {
        var models:[T] = []
        for json in value {
            do {
                let dictData = try JSONSerialization.data(withJSONObject: json.dictionaryObject ?? [String: Any](), options: .prettyPrinted)
                let model = try JSONDecoder().decode(type.self, from: dictData)
                models.append(model)
            } catch {
                print("DataDecoderArrayTransform Error : \(error)")
            }
        }
        return models
    }
}

extension APIToken {
    func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: "APIToken")
    }
    
    func token() -> String? {
        return UserDefaults.standard.value(forKey: "APIToken") as? String
    }
    
    func clearToken() {
        UserDefaults.standard.set(nil, forKey: "APIToken")
    }
}
