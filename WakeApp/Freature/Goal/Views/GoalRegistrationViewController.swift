//
//  GoalRegistrationViewController.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/07/03.
//

import UIKit
import RxSwift
import RxCocoa

class GoalRegistrationViewController: UIViewController {

    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var registrationButton: UIButton! {
        didSet {
            registrationButton.layer.cornerRadius = Const.LargeBlueButtonCorner
        }
    }
    @IBOutlet weak var startDateTextField: UITextField!
    @IBOutlet weak var endDateTextField: UITextField!
    @IBOutlet weak var dateErrorLabel: UILabel!
    @IBOutlet weak var statusSegmentedControl: UISegmentedControl!
    
    private var viewModel: GoalRegistrationViewModel!
    private let disposeBag = DisposeBag()
    private var startDatePicker = UIDatePicker()
    private var endDatePicker = UIDatePicker()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpViewModel()
        setUpPickerView()
    }

    
    // MARK: - Action
    
    private func setUpViewModel() {
        viewModel = GoalRegistrationViewModel()
        let startDatePickerObserver = startDatePicker.rx.controlEvent(.valueChanged)
                    .map { [weak self] in
                        self?.startDatePicker.date
                    }
                    .share()
        let endDatePickerObserver = endDatePicker.rx.controlEvent(.valueChanged)
                    .map { [weak self] in
                        self?.endDatePicker.date
                    }
                    .share()
        let inputs = GoalRegistrationViewModelInputs(startDatePickerObserver: startDatePickerObserver,
                                                     endDatePickerObserver: endDatePickerObserver)
        viewModel.setUp(inputs: inputs)
        
        // エラーアラート表示
        viewModel.outputs.errorAlertDriver
            .drive(onNext: { [weak self] error in
                guard let self else { return }
                present(createErrorAlert(title: error), animated: true)
            })
            .disposed(by: disposeBag)
        
        // 画面を閉じる
        viewModel.outputs.dismissScreenDriver
            .drive(onNext: { [weak self] in
                self?.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
        
        // 終了日付が開始日付を上回った場合のエラー
        viewModel.outputs.dateErrorDriver
            .drive(dateErrorLabel.rx.text)
            .disposed(by: disposeBag)
        
        // Date型を変換してバインド
        viewModel.outputs.startDateTextDriver
            .drive(startDateTextField.rx.text)
            .disposed(by: disposeBag)
        
        // Date型を変換してバインド
        viewModel.outputs.endDateTextDriver
            .drive(endDateTextField.rx.text)
            .disposed(by: disposeBag)
        
    }
    
    private func setUpPickerView() {
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
    
    /// Firestoreに保存
    @IBAction func tapRegistrationButton(_ sender: Any) {
        guard let title = titleTextField.text else {
            return
        }
        
        let goalData = GoalData(title: title,
                                startDate: startDatePicker.date,
                                endDate: endDatePicker.date,
                                status: statusSegmentedControl.selectedSegmentIndex)
        viewModel.saveGoadlData(date: goalData)
    }
}
