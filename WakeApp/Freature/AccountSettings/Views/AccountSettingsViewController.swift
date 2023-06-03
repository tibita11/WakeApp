//
//  AccountSettingsViewController.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/06/01.
//

import UIKit
import RxSwift

class AccountSettingsViewController: UIViewController {
    
    @IBOutlet weak var nextButton: UIButton! {
        didSet {
            nextButton.layer.cornerRadius = Const.LargeBlueButtonCorner
        }
    }
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var birthdayTextField: UITextField!
    @IBOutlet weak var userNameValidationLabel: UILabel!
    private let viewModel = AccountSettingsViewModel()
    private let disposeBag = DisposeBag()
    
    
    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUp()
    }
    
    
    // MARK: - Action
    
    @IBAction func tapNextButton(_ sender: Any) {
        
    }
    
    private func setUp() {
        // ViewModel設定
        let input = AccountSettingsViewModelInput(userNameTextFieldObserver: userNameTextField.rx.text.asObservable())
        viewModel.setUp(input: input)
        // UserNameバリデーション
        viewModel.output.userNameValidationDriver
            .drive(onNext: { [weak self] error in
                guard let self else { return }
                let status: (text: String, isEnabled: Bool, color: UIColor) =
                    error == "" ? ("", true, Const.mainBlueColor) : (error, false, UIColor.systemGray2)
                userNameValidationLabel.text = status.text
                // ボタンの状態、色
                nextButton.isEnabled = status.1
                nextButton.backgroundColor = status.2
            })
            .disposed(by: disposeBag)
    }
    
}
