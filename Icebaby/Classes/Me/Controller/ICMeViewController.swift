//
//  ICMeViewController.swift
//  Icebaby
//
//  Created by Henry.Liao on 2020/11/27.
//

import UIKit
import RxCocoa
import RxSwift

class ICMeViewController: UIViewController {
    
    // Public
    public var viewModel: ICMeViewModel?
    
    // Rx
    private let disposeBag = DisposeBag()

    @IBOutlet weak var logoutButton: UIButton!
    
}

//MARK: - Life Cycle
extension ICMeViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "我的"
        bindViewModel()
    }
}

//MARK: - Bind
extension ICMeViewController {
    private func bindViewModel() {
        let input = ICMeViewModel.Input(logout: logoutButton.rx.tap.asDriver(onErrorJustReturn: ()))
        viewModel?.transform(input: input)
    }
}
