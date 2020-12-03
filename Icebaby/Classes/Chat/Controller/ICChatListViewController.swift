//
//  ICChatListViewController.swift
//  Icebaby
//
//  Created by Henry.Liao on 2020/12/3.
//

import UIKit
import RxCocoa
import RxSwift


class ICChatListViewController: ICBaseViewController {

    // Public
    public var viewModel: ICChatListViewModel?
    
    // Rx
    private let disposeBag = DisposeBag()
    

}

//MARK: - Life Cycle
extension ICChatListViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "聊天"
        
    }
}
