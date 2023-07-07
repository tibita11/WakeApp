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
    @IBOutlet weak var titleErrorLabel: UILabel!
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
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    init(documentID: String) {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
                                                     endDatePickerObserver: endDatePickerObserver,
                                                     titleTextFieldObserver: titleTextField.rx.text.asObservable())
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
        
        // 目標名が空欄の場合のエラー
        viewModel.outputs.titleErrorDriver
            .drive(titleErrorLabel.rx.text)
            .disposed(by: disposeBag)
        
        // バリデーションがOKの場合、登録ボタンをEnabledに変更
        viewModel.outputs.registerButtonDriver
            .drive(onNext: { [weak self] bool in
                self?.registrationButton.isEnabled = bool
                self?.registrationButton.backgroundColor = bool ? Const.mainBlueColor : UIColor.systemGray2
            })
            .disposed(by: disposeBag)
        
        // 未送信アラート表示
        viewModel.outputs.unsentAlertDriver
            .drive(onNext: { [weak self] in
                guard let self else { return }
                let action = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                    guard let self else { return }
                    dismiss(animated: true)
                }
               present(createUnsentAlert(action: action), animated: true)
            })
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
        let goalData = GoalData(title: titleTextField.text!,
                                startDate: startDatePicker.date,
                                endDate: endDatePicker.date,
                                status: statusSegmentedControl.selectedSegmentIndex)
        viewModel.saveGoadlData(date: goalData)
    }
}
