//
//  TodoRegistrationViewController.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/07/10.
//

import UIKit
import RxSwift
import RxCocoa

class TodoRegistrationViewController: UIViewController {

    @IBOutlet weak var registerButton: UIButton! {
        didSet {
            registerButton.layer.cornerRadius = Const.LargeBlueButtonCorner
        }
    }
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var titleErrorLabel: UILabel!
    
    private let viewModel = TodoRegistrationViewModel()
    private let disposeBag = DisposeBag()
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setUpViewModel()
    }
    
    
    // MARK: - Action
    
    private func setUpViewModel() {
        let inputs = TodoRegistrationViewModelInputs(
            titleTextFieldObserver: titleTextField.rx.text.asObservable()
        )
        viewModel.setUp(inputs: inputs)
        
        // Titleバリデーション結果をバインド
        viewModel.outputs.titleErrorTextDeriver
            .drive(titleErrorLabel.rx.text)
            .disposed(by: disposeBag)
    }
    
    
}
