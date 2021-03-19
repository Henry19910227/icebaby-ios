//
//  ICLobbyCellViewModel.swift
//  Icebaby
//
//  Created by 廖冠翰 on 2020/12/3.
//

import UIKit
import RxCocoa
import RxSwift

class ICLobbyCellViewModel: NSObject {
    
    //Model
    public var model: ICUserBrief? {
        didSet {
            guard let model = model else { return }
            bindModel(model)
        }
    }
    
    //Rx
    private var disposeBag = DisposeBag()
    private let nameSubject = ReplaySubject<String>.create(bufferSize: 1)
    
    
    //Output
    public var name: Driver<String>
    
    override init() {
        name = nameSubject.asDriver(onErrorJustReturn: "")
    }
}

//MARK: - Bind Model
extension ICLobbyCellViewModel {
    private func bindModel(_ model: ICUserBrief) {
        nameSubject.onNext(model.info?.nickname ?? "")
    }
}

//MARK: - Other
extension ICLobbyCellViewModel {
    public func clear() {
        disposeBag = DisposeBag()
    }
}
