//
//  ICLobbyViewController.swift
//  Icebaby
//
//  Created by Henry.Liao on 2020/12/2.
//

import UIKit

class ICLobbyViewController: ICBaseViewController {
    
    public var viewModel: ICLobbyViewModel?
    
    // UI
    @IBOutlet weak var tableView: UITableView!
}

// MARK: - Life Cycle
extension ICLobbyViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource
extension ICLobbyViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ICLobbyCell.self)) as! ICLobbyCell
        return cell
    }
}

extension ICLobbyViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}

