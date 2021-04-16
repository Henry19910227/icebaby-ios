//
//  ICMeViewModel.swift
//  Icebaby
//
//  Created by Henry.Liao on 2021/4/16.
//

import UIKit
import RxCocoa
import RxSwift
import SwiftyJSON

class ICMeViewModel: NSObject {
    struct Input {
        public let logout: Driver<Void>
    }
    
    struct Output {
        
    }
}

// MARK: - Transform
extension ICMeViewModel {
    @discardableResult func transform(input: Input) -> Output {
        
        return Output()
    }
}
