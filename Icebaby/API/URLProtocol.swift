//
//  URLProtocol.swift
//  Icebaby
//
//  Created by 廖冠翰 on 2020/11/27.
//

import Foundation

protocol CKBaseURL {
    var baseURL: URL { get }
}
protocol CKLoginURL: CKBaseURL {
    var registerURL: URL { get }
    var loginURL: URL { get }
}
protocol CKCourtURL: CKBaseURL {
    var getLocationsURL: URL { get }
    var getLocationDetailURL: URL { get }
    var checkin: URL { get }
    var currentCheckin: URL { get }
    var getFavoriteCourtURL: URL { get }
    var inCourtRange: URL { get }
}
protocol CKCourtDetailURL: CKBaseURL {
    var getCourtDetailURL: URL { get }
    var addFavoriteURL: URL { get }
    var deleteFavoriteURL: URL { get }
}
protocol CKUserURL: CKBaseURL {
    var userDetailURL: URL { get }
    var editUserDetailURL: URL { get }
    var editUserImageURL: URL { get }
}
protocol CKMessageURL: CKBaseURL {
    var getMessageURL: URL { get }
    var addMessageURL: URL { get }
}
protocol CKFavoriteURL: CKBaseURL {
    var getFavoriteCourtURL: URL { get }
    var addFavoriteURL: URL { get }
    var deleteFavoriteURL: URL { get }
}


extension CKBaseURL {
    var baseURL: URL {
        return URL(string: "https://chuck-sit.dot-tw.com")!
    }
}
extension CKLoginURL {
    var registerURL: URL {
        return URL(string: "\(baseURL)/WebBridge/api/User/Register")!
    }
    var loginURL: URL {
        return URL(string: "\(baseURL)/WebBridge/api/User/Login")!
    }
}
extension CKCourtURL {
    var getLocationsURL: URL {
        return URL(string: "\(baseURL)/WebBridge/api/Court/GetLocations")!
    }
    var getLocationDetailURL: URL {
        return URL(string: "\(baseURL)/WebBridge/api/Court/GetLocationDetail")!
    }
    var checkin: URL {
        return URL(string: "\(baseURL)/WebBridge/api/Court/Checkin")!
    }
    var currentCheckin: URL {
        return URL(string: "\(baseURL)/WebBridge/api/User/GetSelfCurrentCheckinCourt")!
    }
    var findCourt: URL {
        return URL(string: "\(baseURL)/WebBridge/api/Court/FindNotice")!
    }
    var getFavoriteCourtURL: URL {
        return URL(string: "\(baseURL)/WebBridge/api/User/GetSelfFavoriteCourt")!
    }
    var inCourtRange: URL {
        return URL(string: "\(baseURL)/WebBridge/api/Court/InCourtRange")!
    }
}
extension CKCourtDetailURL {
    var getCourtDetailURL: URL {
        return URL(string: "\(baseURL)/WebBridge/api/Court/GetDetail")!
    }
    var addFavoriteURL: URL {
        return URL(string: "\(baseURL)/WebBridge/api/Court/AddFavorite")!
    }
    var deleteFavoriteURL: URL {
        return URL(string: "\(baseURL)/WebBridge/api/Court/DeleteFavorite")!
    }
}
extension CKUserURL {
    var userDetailURL: URL {
        return URL(string: "\(baseURL)/WebBridge/api/User/GetSomeoneDetail")!
    }
    var editUserDetailURL: URL {
        return URL(string: "\(baseURL)/WebBridge/api/User/EditSelfDetail")!
    }
    var editUserImageURL: URL {
        return URL(string: "\(baseURL)/WebBridge/api/User/UploadSelfImage")!
    }
}
extension CKMessageURL {
    var getMessageURL: URL {
        return URL(string: "\(baseURL)/WebBridge/api/Court/GetMessage")!
    }
    var addMessageURL: URL {
        return URL(string: "\(baseURL)/WebBridge/api/Court/AddMessage")!
    }
    var deleteMessageURL: URL {
        return URL(string: "\(baseURL)/WebBridge/api/Court/DeleteMessage")!
    }
}
extension CKFavoriteURL {
    var getFavoriteCourtURL: URL {
        return URL(string: "\(baseURL)/WebBridge/api/User/GetSelfFavoriteCourt")!
    }
    var addFavoriteURL: URL {
        return URL(string: "\(baseURL)/WebBridge/api/Court/AddFavorite")!
    }
    var deleteFavoriteURL: URL {
        return URL(string: "\(baseURL)/WebBridge/api/Court/DeleteFavorite")!
    }
}
