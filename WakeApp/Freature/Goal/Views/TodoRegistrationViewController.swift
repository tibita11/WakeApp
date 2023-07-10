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
    @IBOutlet weak var statusSegmentedControl: UISegmentedControl!
    
    private let viewModel = TodoRegistrationViewModel()
    private let disposeBag = DisposeBag()
    private let startDatePicker = UIDatePicker()
    private let endDatePicker = UIDatePicker()
    private let documentID: String!
    
    
    // MARK: - View Life Cycle
    
    init(documentID: String) {
        self.documentID = documentID
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
        
        // エラーがない場合のみ、登録ボタンをタップ可能にする
        viewModel.outputs.registerButtonDriver
            .drive(onNext: { [weak self] bool in
                guard let self else { return }
                registerButton.isEnabled = bool
                registerButton.backgroundColor
                    = bool ? Const.mainBlueColor : UIColor.systemGray2
            })
            .disposed(by: disposeBag)
        
        // ErrorAlert表示
        viewModel.outputs.errorAlertDriver
            .drive(onNext: { [weak self] error in
                guard let self else { return }
                present(createErrorAlert(title: error), animated: true)
            })
            .disposed(by: disposeBag)
        
        // 画面を閉じる
        viewModel.outputs.dismissDriver
            .drive(onNext: { [weak self] in
                guard let self else { return }
                dismiss(animated: true)
            })
            .disposed(by: disposeBag)
        
        // オフライン時の送信待ちアラート表示
        viewModel.outputs.unsentAlertDriver
            .drive(onNext: { [weak self] in
                guard let self else { return }
                let okAction = UIAlertAction(title: "OK", style: .default) {
                    [weak self] _ in
                    self?.dismiss(animated: true)
                }
                present(createUnsentAlert(action: okAction), animated: true)
            })
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
    
    @IBAction func tapRegisterButton(_ sender: Any) {
        let todoData = TodoData(title: titleTextField.text!,
                                startDate: startDatePicker.date,
                                endDate: endDatePicker.date,
                                status: statusSegmentedControl.selectedSegmentIndex)
        
        viewModel.saveTodoData(documentID: documentID, todoData: todoData)
    }
    
}
