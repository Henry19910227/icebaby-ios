//
//  ICViewModel.swift
//  Icebaby
//
//  Created by 廖冠翰 on 2020/11/26.
//

import UIKit

protocol ICViewModel {
    associatedtype Input
    associatedtype Output
    func transform(input: Input) -> Output
}
