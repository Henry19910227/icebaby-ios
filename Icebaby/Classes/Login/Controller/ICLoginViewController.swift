//
//  ICLoginViewController.swift
//  Icebaby
//
//  Created by 廖冠翰 on 2020/11/27.
//

import UIKit
import RxSwift
import RxCocoa
import Toast_Swift

class ICLoginViewController: ICBaseViewController {
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
        let output = viewModel?.transform(input: input)
        
        output?
            .showLoading
            .drive(rx.isShowLoading)
            .disposed(by: disposeBag)
        
        output?
            .showErrorMsg
            .drive(onNext: { [unowned self] (msg) in
                self.view.makeToast(msg, duration: 1.0, position: .top)
            })
            .disposed(by: disposeBag)
    }
}
