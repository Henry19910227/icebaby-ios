//
//  URLProtocol.swift
//  Icebaby
//
//  Created by 廖冠翰 on 2020/11/27.
//

import Foundation

protocol ICBaseURL {
    var baseURL: URL { get }
}
protocol ICLoginURL: ICBaseURL {
    var registerURL: URL { get }
    var loginURL: URL { get }
}
protocol ICLobbyURL: ICBaseURL {
    var usersURL: URL { get }
}
protocol ICCourtURL: ICBaseURL {
    var getLocationsURL: URL { get }
    var getLocationDetailURL: URL { get }
    var checkin: URL { get }
    var currentCheckin: URL { get }
    var getFavoriteCourtURL: URL { get }
    var inCourtRange: URL { get }
}
protocol ICCourtDetailURL: ICBaseURL {
    var getCourtDetailURL: URL { get }
    var addFavoriteURL: URL { get }
    var deleteFavoriteURL: URL { get }
}
protocol ICUserURL: ICBaseURL {
    var userDetailURL: URL { get }
    var editUserDetailURL: URL { get }
    var editUserImageURL: URL { get }
}
protocol ICMessageURL: ICBaseURL {
    var getMessageURL: URL { get }
    var addMessageURL: URL { get }
}
protocol ICFavoriteURL: ICBaseURL {
    var getFavoriteCourtURL: URL { get }
    var addFavoriteURL: URL { get }
    var deleteFavoriteURL: URL { get }
}


extension ICBaseURL {
    var baseURL: URL {
        return URL(string: "http://127.0.0.1:9090")!
    }
}
extension ICLoginURL {
    var registerURL: URL {
        return URL(string: "\(baseURL)/icebaby/v1/register")!
    }
    var loginURL: URL {
        return URL(string: "\(baseURL)/icebaby/v1/login")!
    }
}
extension ICLobbyURL {
    var usersURL: URL {
        return URL(string: "\(baseURL)/icebaby/v1/users")!
    }
}
extension ICCourtURL {
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
extension ICCourtDetailURL {
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
extension ICUserURL {
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
extension ICMessageURL {
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
extension ICFavoriteURL {
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
