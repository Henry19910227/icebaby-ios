//
//  ICUserViewController.swift
//  Icebaby
//
//  Created by 廖冠翰 on 2020/12/3.
//

import UIKit
import RxCocoa
import RxSwift

class ICUserViewController: ICBaseViewController {

    // VM
    public var viewModel: ICUserViewModel?
    
    // Rx
    private let disposeBag = DisposeBag()
    private let trigger = PublishSubject<Void>()
    private let isDisplay = PublishSubject<Bool>()
    
    // UI
    @IBOutlet weak var uidLabel: UILabel!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var birthdayLabel: UILabel!
    @IBOutlet weak var chatButton: UIButton!
    @IBOutlet weak var testImageView: UIImageView!
    
}

//MARK: - Life Cycle
extension ICUserViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
        testImageView.layer.cornerRadius = testImageView.bounds.size.height * 0.5
        testImageView.layer.masksToBounds = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trigger.onNext(())
        isDisplay.onNext(true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        isDisplay.onNext(false)
    }
}

extension ICUserViewController {
    private func bindViewModel() {
        let input = ICUserViewModel.Input(trigger: trigger.asDriver(onErrorJustReturn: ()),
                                          isDisplay: isDisplay.asDriver(onErrorJustReturn: false),
                                          chatTap: chatButton.rx.tap.asDriver())
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
        
        output?
            .uid
            .map({ (uid) -> String in
                return String(uid)
            })
            .drive(uidLabel.rx.text)
            .disposed(by: disposeBag)
        
        output?
            .nickname
            .drive(nicknameLabel.rx.text)
            .disposed(by: disposeBag)
        
        output?
            .birthday
            .drive(birthdayLabel.rx.text)
            .disposed(by: disposeBag)
    }
}
