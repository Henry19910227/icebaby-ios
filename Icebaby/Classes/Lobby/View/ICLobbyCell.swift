//
//  ICLobbyCell.swift
//  Icebaby
//
//  Created by Henry.Liao on 2020/12/2.
//

import UIKit
import RxSwift
import RxCocoa

class ICLobbyCell: UITableViewCell {

    //Public
    public var viewModel: ICLobbyCellViewModel? {
        didSet {
            guard let viewModel = viewModel else { return }
            bindViewModel(viewModel)
        }
    }
    
    //Rx
    private var disposeBag = DisposeBag()
    
    //UI
    @IBOutlet weak var nicknameLabel: UILabel!
    

}

//MARK: - Life Cycle
extension ICLobbyCell {
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        viewModel?.clear()
    }
}

//MARK: - Life Cycle
extension ICLobbyCell {
    private func bindViewModel(_ viewModel: ICLobbyCellViewModel) {
        viewModel
            .name
            .drive(nicknameLabel.rx.text)
            .disposed(by: disposeBag)
    }
}
