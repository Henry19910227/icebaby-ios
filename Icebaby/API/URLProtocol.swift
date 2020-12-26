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
    func userDetailURL(userID: Int) -> URL
}
protocol ICChatURL: ICBaseURL {
    var newChatURL: URL { get }
    var myChannelsURL: URL { get }
    func updateReadDateURL(channelID: String) -> URL
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
    
    func userDetailURL(userID: Int) -> URL {
        return URL(string: "\(baseURL)/icebaby/v1/user/\(userID)/detail")!
    }
}
extension ICChatURL {
    var newChatURL: URL {
        return URL(string: "\(baseURL)/icebaby/v1/chat/channel")!
    }
    
    var myChannelsURL: URL {
        return URL(string: "\(baseURL)/icebaby/v1/chat/mychannels")!
    }
    
    func updateReadDateURL(channelID: String) -> URL {
        return URL(string: "\(baseURL)/icebaby/v1/chat/read_date/\(channelID)")!
    }
}
