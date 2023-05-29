//
//  NewAccountRegistrationViewController.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/05/29.
//

import UIKit
import RxSwift
import RxCocoa

class NewAccountRegistrationViewController: UIViewController {

    @IBOutlet weak var newRegistrationButton: UIButton! {
        didSet {
            newRegistrationButton.layer.cornerRadius = Const.LargeBlueButtonCorner
        }
    }
    @IBOutlet weak var googleRegistrationButton: UIButton! {
        didSet {
            googleRegistrationButton.layer.cornerRadius = Const.LargeBlueButtonCorner
        }
    }
    @IBOutlet weak var appleRegistrationoButton: UIButton! {
        didSet {
            appleRegistrationoButton.layer.cornerRadius = Const.LargeBlueButtonCorner
        }
    }
    private let viewModel = NewAccountRegistrationViewModel()
    private let disposeBag = DisposeBag()
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUp()
    }
    
    
    // MARK: - Action
    
    @IBAction func tapGoogleRegistrationButton(_ sender: Any) {
        viewModel.googleSignIn(withPresenting: self)
    }
    
    private func setUp() {
        // エラーアラート表示
        viewModel.output.errorAlertDriver
            .drive(onNext: { [weak self] alert in
                self?.present(alert, animated: true)
            })
            .disposed(by: disposeBag)
    }

}
