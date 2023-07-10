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
    @IBOutlet weak var startDateTextField: UITextField!
    @IBOutlet weak var endDateTextField: UITextField!
    @IBOutlet weak var dateErrorLabel: UILabel!
    
    private let viewModel = TodoRegistrationViewModel()
    private let disposeBag = DisposeBag()
    private let startDatePicker = UIDatePicker()
    private let endDatePicker = UIDatePicker()
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setUpViewModel()
        setUpDatePicker()
    }
    
    
    // MARK: - Action
    
    private func setUpViewModel() {
        let startDateObserver = startDatePicker.rx.controlEvent(.valueChanged)
            .map { [weak self] in
                self?.startDatePicker.date
            }
            .share()
        let endDateObserver = endDatePicker.rx.controlEvent(.valueChanged)
            .map { [weak self] in
                self?.endDatePicker.date
            }
            .share()
        let inputs = TodoRegistrationViewModelInputs(
            titleTextFieldObserver: titleTextField.rx.text.asObservable(),
            startDatePickerObserver: startDateObserver,
            endDatePickerObserver: endDateObserver
        )
        viewModel.setUp(inputs: inputs)
        
        // Titleバリデーション結果をバインド
        viewModel.outputs.titleErrorTextDriver
            .drive(titleErrorLabel.rx.text)
            .disposed(by: disposeBag)
        
        // Text変換後の開始日付をバインド
        viewModel.outputs.startDateTextDriver
            .drive(startDateTextField.rx.text)
            .disposed(by: disposeBag)
        
        // Text変換後の終了日付をバインド
        viewModel.outputs.endDateTextDriver
            .drive(endDateTextField.rx.text)
            .disposed(by: disposeBag)
        
        // 終了日付が開始日付よりも小さい場合に表示されるエラー
        viewModel.outputs.dateErrorTextDriver
            .drive(dateErrorLabel.rx.text)
            .disposed(by: disposeBag)
    }
    
    private func setUpDatePicker() {
        // 開始日付
        startDatePicker.preferredDatePickerStyle = .wheels
        startDatePicker.datePickerMode = .date
        startDatePicker.locale = Locale(identifier: "ja_JP")
        startDateTextField.inputView = startDatePicker
        // 終了日付
        endDatePicker.preferredDatePickerStyle = .wheels
        endDatePicker.datePickerMode = .date
        endDatePicker.locale = Locale(identifier: "ja_JP")
        endDateTextField.inputView = endDatePicker
    }
    
    
}
