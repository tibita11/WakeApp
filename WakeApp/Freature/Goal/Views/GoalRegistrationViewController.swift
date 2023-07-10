//
//  GoalRegistrationViewController.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/07/03.
//

import UIKit
import RxSwift
import RxCocoa

/// 新規と更新で画面を共有するため、判別用に準備
enum GoalRegistrationStatus {
    case create
    case update
}

class GoalRegistrationViewController: UIViewController {

    @IBOutlet weak var headingLabel: UILabel! {
        didSet {
            if status == .update {
                headingLabel.text = "目標編集"
            }
        }
    }
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var registrationButton: UIButton! {
        didSet {
            registrationButton.layer.cornerRadius = Const.LargeBlueButtonCorner
            
            switch status {
            case .create:
                registrationButton.addTarget(self, action: #selector(tapRegistrationButton), for: .touchUpInside)
            case .update:
                registrationButton.addTarget(self, action: #selector(tapUpdateButton), for: .touchUpInside)
                registrationButton.setTitle("更新", for: .normal)
            default:
                break
            }
        }
    }
    @IBOutlet weak var startDateTextField: UITextField!
    @IBOutlet weak var endDateTextField: UITextField!
    @IBOutlet weak var dateErrorLabel: UILabel!
    @IBOutlet weak var titleErrorLabel: UILabel!
    @IBOutlet weak var statusSegmentedControl: UISegmentedControl!
    @IBOutlet weak var deleteButton: UIButton! {
        didSet {
            if status == .update {
                deleteButton.isHidden = false
            }
        }
    }
    
    private var viewModel: GoalRegistrationViewModel!
    private let disposeBag = DisposeBag()
    private var startDatePicker = UIDatePicker()
    private var endDatePicker = UIDatePicker()
    private var status: GoalRegistrationStatus!
    private var goalData: GoalData? = nil
    
    // MARK: - View Life Cycle
    
    init() {
        status = .create
        super.init(nibName: nil, bundle: nil)
    }
    
    init(goalData: GoalData) {
        self.status = .update
        self.goalData = goalData
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpViewModel()
        setUpPickerView()
        setUpInitialData()
    }

    
    // MARK: - Action
    
    /// 更新の場合に、初期値をセット
    private func setUpInitialData() {
        if status == .update {
            guard let goalData else { return }
            titleTextField.text = goalData.title
            titleTextField.sendActions(for: .valueChanged)
            startDatePicker.date = goalData.startDate
            startDatePicker.sendActions(for: .valueChanged)
            endDatePicker.date = goalData.endDate
            endDatePicker.sendActions(for: .valueChanged)
            statusSegmentedControl.selectedSegmentIndex = goalData.status
        }
    }
    
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
    @objc private func tapRegistrationButton() {
        let goalData = GoalData(title: titleTextField.text!,
                                startDate: startDatePicker.date,
                                endDate: endDatePicker.date,
                                status: statusSegmentedControl.selectedSegmentIndex)
        viewModel.saveGoalData(data: goalData)
    }
    
    /// Firestoreのデータを更新
    @objc private func tapUpdateButton() {
        guard let goalData else { return }
        let newGoalData = GoalData(title: titleTextField.text!,
                                startDate: startDatePicker.date,
                                endDate: endDatePicker.date,
                                status: statusSegmentedControl.selectedSegmentIndex)
        viewModel.updateGoalData(documentID: goalData.documentID, data: newGoalData)
    }
    
    @IBAction func tapDeleteButton(_ sender: Any) {
        present(createDeleteAlert(), animated: true)
    }
    
    /// 削除ボタンタップ時の確認アラート
    ///
    /// - Returns : 作成したアラートコントローラ
    private func createDeleteAlert() -> UIAlertController {
        let title = "「\(goalData!.title)」を削除してよろしいですか？"
        let alertController = UIAlertController(title: title,
                                                message: nil,
                                                preferredStyle: .alert)
        let okAction = UIAlertAction(title: "はい", style: .default) { [weak self] _ in
            guard let self else { return }
            // 削除処理に移る
            viewModel.deleteGoalData(documentID: goalData!.documentID)
        }
        let cancelAction = UIAlertAction(title: "いいえ", style: .cancel)
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        return alertController
    }
}
