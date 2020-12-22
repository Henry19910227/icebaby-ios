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
    
    //Public
    public var viewModel: ICLoginViewModel?
    
    //Rx
    private let disposeBag = DisposeBag()
    private let trigger = PublishSubject<Void>()
    
    //UI
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var mobileTextField: UITextField!
    @IBOutlet weak var pwdTextField: UITextField!
}

//MARK: - Life Cycle
extension ICLoginViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
        trigger.onNext(())
    }
}

//MARK: - Bind
extension ICLoginViewController {
    private func bindViewModel() {
        let input = ICLoginViewModel.Input(trigger: trigger.asDriver(onErrorJustReturn: ()),
                                           loginTap: loginButton.rx.tap.asDriver(),
                                           identifier: mobileTextField.rx.text.asDriver(),
                                           password: pwdTextField.rx.text.asDriver())
        let output = viewModel?.transform(input: input)
        
        output?
            .defaultMobile
            .drive(mobileTextField.rx.text)
            .disposed(by: disposeBag)
        
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
