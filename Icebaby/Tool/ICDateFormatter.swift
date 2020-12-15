//
//  ICDateFormatter.swift
//  Icebaby
//
//  Created by Henry.Liao on 2020/12/15.
//

import UIKit

class ICDateFormatter: NSObject {
    
    private let dateFormatter = DateFormatter()
    
    public func dateStringToDate( _ dateString: String, _ formatter: String) -> Date? {
        dateFormatter.locale = Locale(identifier: "zh_Hant_TW")
        dateFormatter.dateFormat = formatter
        return dateFormatter.date(from: dateString)
    }
    
    public func dateToDateString( _ date: Date?, _ formatter: String) -> String? {
        guard let date = date else { return nil }
        dateFormatter.locale = Locale(identifier: "zh_Hant_TW")
        dateFormatter.dateFormat = formatter
        return dateFormatter.string(from: date)
    }
    
    public func dateStringToDateString( _ beforeDateString: String,
                                        before beforeFormatter: String,
                                        after afterFormatter: String) -> String? {
        
        let date = dateStringToDate(beforeDateString, beforeFormatter)
        return dateToDateString(date, afterFormatter)
    }
    
    public func dateToDate( _ date: Date?, _ formatter: String) -> Date? {
        let dateString = dateToDateString(date, formatter) ?? ""
        return dateStringToDate(dateString, formatter)
    }
    
    /** 取得兩個日期相差多少秒*/
    public func dateIntervalSeconds(_ firstDate: Date, _ secondDate: Date) -> TimeInterval {
        var timeInterval = firstDate.timeIntervalSince(secondDate)
        if timeInterval < 0 { timeInterval = -timeInterval }
        return timeInterval
    }
}
