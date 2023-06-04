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
    private var datePicker = UIDatePicker()
    
    
    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUp()
    }
    
    
    // MARK: - Action
    
    @IBAction func tapNextButton(_ sender: Any) {
        
    }
    
    private func setUp() {
        setUpDatePicker()
        // ViewModel設定
        let input = AccountSettingsViewModelInput(userNameTextFieldObserver: userNameTextField.rx.text.asObservable(), datePickerObserver: datePicker.rx.controlEvent(.valueChanged).map {[weak self] in self?.datePicker.date })
        viewModel.setUp(input: input)
        // バリデーション結果を反映
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
        // textに日付を表示
        viewModel.output.birthdayTextFieldDriver
            .drive(birthdayTextField.rx.text)
            .disposed(by: disposeBag)
        
    }
    
    private func setUpDatePicker() {
        let toolBar = UIToolbar(frame: CGRect(origin: .zero, size: CGSize(width: 100.0, height: 45.0)))
        let spaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let doneButton = UIBarButtonItem(title: "完了", style: .done, target: self, action: #selector(tapDoneButton))
        let clearButton = UIBarButtonItem(title: "クリア", style: .plain, target: self, action: #selector(tapClearButton))
        toolBar.items = [clearButton, spaceItem, doneButton]
        toolBar.sizeToFit()
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.datePickerMode = .date
        datePicker.locale = Locale(identifier: "ja_JP")
        birthdayTextField.inputView = datePicker
        birthdayTextField.inputAccessoryView = toolBar
    }
    
    /// ToolBarに設置する完了ボタン
    @objc private func tapDoneButton() {
        birthdayTextField.resignFirstResponder()
    }
    
    /// ToolBarに設置するクリアボタン
    @objc private func tapClearButton() {
        birthdayTextField.text = ""
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
}
