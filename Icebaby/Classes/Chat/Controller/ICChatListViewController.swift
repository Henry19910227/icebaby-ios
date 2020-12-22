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
    private let trigger = PublishSubject<Void>()
    private let allowChat = PublishSubject<Bool>()
    
    // UI
    @IBOutlet weak var tableView: UITableView!
    
    // Data
    private var cellVMs: [ICChatListCellViewModel] = []
    
}

//MARK: - Life Cycle
extension ICChatListViewController {
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

//MARK: - UITableViewDataSource
extension ICChatListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellVMs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ICChatListCell.self)) as! ICChatListCell
        cell.viewModel = cellVMs[indexPath.row]
        return cell
    }
}

//MARK: - UITableViewDelegate
extension ICChatListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}

//MARK: - Bind
extension ICChatListViewController {
    func bindViewModel() {
        let itemSelected = tableView.rx.itemSelected.asDriver(onErrorJustReturn: IndexPath())
        let input = ICChatListViewModel.Input(trigger: trigger.asDriver(onErrorJustReturn: ()),
                                              allowChat: allowChat.asDriver(onErrorJustReturn: false),
                                              itemSelected: itemSelected)
        let output = viewModel?.transform(input: input)
        
        output?
            .items
            .drive(onNext: { [unowned self] (cellVMs) in
                self.cellVMs = cellVMs
                self.tableView.reloadData()
            })
            .disposed(by: disposeBag)
        
        output?
            .showErrorMsg
            .drive(onNext: { [unowned self] (msg) in
                self.view.makeToast(msg, duration: 1.0, position: .top)
            })
            .disposed(by: disposeBag)

    }
}
