//
//  ICLobbyViewController.swift
//  Icebaby
//
//  Created by Henry.Liao on 2020/12/2.
//

import UIKit
import RxCocoa
import RxSwift

class ICLobbyViewController: ICBaseViewController {
    
    // Public
    public var viewModel: ICLobbyViewModel?
    
    // Rx
    private let disposeBag = DisposeBag()
    
    // UI
    @IBOutlet weak var tableView: UITableView!
    
    // Data
    private var cellVMs: [ICLobbyCellViewModel] = []
    
}

// MARK: - Life Cycle
extension ICLobbyViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "大廳"
        bindViewModel()
    }
}

// MARK: - Bind
extension ICLobbyViewController {
    private func bindViewModel() {
        let trigger = rx
            .sentMessage(#selector(viewDidAppear(_:)))
            .take(1) //不加入 take(1) 不會有 onCompleted 結果 會一直觀察著 sentMessage
            .map ({ _ in })
            .asDriver(onErrorJustReturn: ())
        
        let itemSelected = tableView.rx.itemSelected.asDriver(onErrorJustReturn: IndexPath())
        
        let input = ICLobbyViewModel.Input(trigger: trigger,
                                           itemSelected: itemSelected)
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
            .items
            .drive(onNext: { [unowned self] (cellVMs) in
                self.cellVMs = cellVMs
                self.tableView.reloadData()
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - UITableViewDataSource
extension ICLobbyViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cellVMs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ICLobbyCell.self)) as! ICLobbyCell
        cell.viewModel = self.cellVMs[indexPath.row]
        return cell
    }
}

extension ICLobbyViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}

