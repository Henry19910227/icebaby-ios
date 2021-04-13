//
//  ICChatListCell.swift
//  Icebaby
//
//  Created by 廖冠翰 on 2020/12/11.
//

import UIKit
import RxCocoa
import RxSwift

class ICChatListCell: UITableViewCell {

    //VM
    public var viewModel: ICChatListCellViewModel? {
        didSet {
            guard let viewModel = viewModel else { return }
            bindViewModel(viewModel)
        }
    }
    
    //Rx
    private var disposeBag = DisposeBag()
    
    //UI
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var msgLabel: UILabel!
    @IBOutlet weak var unreadLabel: UILabel!
    @IBOutlet weak var dotView: UIView!
    
}

//MARK: - Life Cycle
extension ICChatListCell {
    override func awakeFromNib() {
        super.awakeFromNib()
        initUI()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        viewModel?.clear()
    }
}

extension ICChatListCell {
    private func initUI() {
        dotView.layer.masksToBounds = true
        dotView.layer.cornerRadius = dotView.bounds.height * 0.5
    }
}

//MARK: Bind
extension ICChatListCell {
    private func bindViewModel(_ viewModel: ICChatListCellViewModel) {
        viewModel
            .nickname?
            .drive(nameLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel
            .latestMsg?
            .drive(msgLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel
            .unread?
            .map({ (count) -> String in
                return "\(count)"
            })
            .drive(unreadLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel
            .unread?
            .map({ (count) -> Bool in
                return count == 0
            })
            .drive(dotView.rx.isHidden)
            .disposed(by: disposeBag)
        
        viewModel
            .isActivate?
            .drive(onNext: { [unowned self] (isActivate) in
                self.contentView.backgroundColor = isActivate ? .white : .gray
            })
            .disposed(by: disposeBag)
    }
}

//MARK: Other
extension ICChatListCell {
    public func clear() {
        disposeBag = DisposeBag()
    }
}
