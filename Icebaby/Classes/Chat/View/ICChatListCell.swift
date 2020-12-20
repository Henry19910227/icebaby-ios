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
    
}

//MARK: - Life Cycle
extension ICChatListCell {
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        viewModel?.clear()
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
    }
}

//MARK: Other
extension ICChatListCell {
    public func clear() {
        disposeBag = DisposeBag()
    }
}
