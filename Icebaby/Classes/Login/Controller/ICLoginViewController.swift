//
//  ICLoginViewController.swift
//  Icebaby
//
//  Created by 廖冠翰 on 2020/11/27.
//

import UIKit
import RxSwift
import RxCocoa

class ICLoginViewController: UIViewController {
    public var viewModel: ICLoginViewModel?
    private let disposeBag = DisposeBag()
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var mobileTextField: UITextField!
    @IBOutlet weak var pwdTextField: UITextField!
}

//MARK: - Life Cycle
extension ICLoginViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
    }
}

//MARK: - Bind
extension ICLoginViewController {
    private func bindViewModel() {
        let input = ICLoginViewModel.Input(loginTap: loginButton.rx.tap.asDriver(),
                                           identifier: mobileTextField.rx.text.asDriver(),
                                           password: pwdTextField.rx.text.asDriver())
        viewModel?.transform(input: input)
    }
}
