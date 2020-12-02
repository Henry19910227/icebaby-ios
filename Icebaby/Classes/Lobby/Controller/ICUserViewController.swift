//
//  ICUserViewController.swift
//  Icebaby
//
//  Created by 廖冠翰 on 2020/12/3.
//

import UIKit

class ICUserViewController: UIViewController {

    // VM
    public var viewModel: ICUserViewModel?
    
}

//MARK: - Life Cycle
extension ICUserViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
    }
}

extension ICUserViewController {
    private func bindViewModel() {
        let trigger = rx
            .sentMessage(#selector(viewDidAppear(_:)))
            .take(1)
            .map ({ _ in })
            .asDriver(onErrorJustReturn: ())
        
        let input = ICUserViewModel.Input(trigger: trigger)
        viewModel?.transform(input: input)
    }
}
