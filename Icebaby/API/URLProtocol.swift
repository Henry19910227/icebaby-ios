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
    var girlsURL: URL { get }
    func userDetailURL(userID: Int) -> URL
}
protocol ICChatURL: ICBaseURL {
    var newChatURL: URL { get }
    var myChannelsURL: URL { get }
    var getChannel: URL { get }
    func updateReadDateURL(channelID: String) -> URL
    func historyURL(channelID: String) -> URL
}


extension ICBaseURL {
    var baseURL: URL {
        return URL(string: "https://www.icebaby.tk/api/v1")!
    }
}
extension ICLoginURL {
    var registerURL: URL {
        return URL(string: "\(baseURL)/register")!
    }
    var loginURL: URL {
        return URL(string: "\(baseURL)/account/login/mobile")!
    }
}
extension ICLobbyURL {
    var girlsURL: URL {
        return URL(string: "\(baseURL)/user/girls/brief")!
    }
    
    func userDetailURL(userID: Int) -> URL {
        return URL(string: "\(baseURL)/user/detail/\(userID)")!
    }
}
extension ICChatURL {
    var newChatURL: URL {
        return URL(string: "\(baseURL)/icebaby/v1/chat/channel")!
    }
    
    var myChannelsURL: URL {
        return URL(string: "\(baseURL)/icebaby/v1/chat/channels")!
    }
    
    var getChannel: URL {
        return URL(string: "\(baseURL)/icebaby/v1/chat/channel")!
    }
    
    func updateReadDateURL(channelID: String) -> URL {
        return URL(string: "\(baseURL)/icebaby/v1/chat/read_date/\(channelID)")!
    }
    
    func historyURL(channelID: String) -> URL {
        return URL(string: "\(baseURL)/icebaby/v1/chat/history/\(channelID)")!
    }
}
