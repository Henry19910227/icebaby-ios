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
    private let allowChat = PublishSubject<Bool>()
    
    // UI
    @IBOutlet weak var uidLabel: UILabel!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var birthdayLabel: UILabel!
    @IBOutlet weak var chatButton: UIButton!
    
}

//MARK: - Life Cycle
extension ICUserViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trigger.onNext(())
        allowChat.onNext(true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        allowChat.onNext(false)
    }
}

extension ICUserViewController {
    private func bindViewModel() {
        let input = ICUserViewModel.Input(trigger: trigger.asDriver(onErrorJustReturn: ()),
                                          allowChat: allowChat.asDriver(onErrorJustReturn: false),
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
