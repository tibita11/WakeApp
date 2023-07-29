//
//  TodoRegistrationViewController.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/07/10.
//

import UIKit
import RxSwift
import RxCocoa

enum ActionType {
    case update
    case create
}

class TodoRegistrationViewController: UIViewController {

    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var registerButton: UIButton! {
        didSet {
            registerButton.layer.cornerRadius = Const.LargeBlueButtonCorner
        }
    }
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var titleErrorLabel: UILabel!
    @IBOutlet weak var dateErrorLabel: UILabel!
    @IBOutlet weak var statusSegmentedControl: UISegmentedControl!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var focusSwitch: UISwitch!
    @IBOutlet weak var startDatePicker: UIDatePicker!
    @IBOutlet weak var endDatePicker: UIDatePicker!
    
    private let viewModel = TodoRegistrationViewModel()
    private let disposeBag = DisposeBag()
    /// 登録のため、親コレクションのドキュメントIDを保持
    private var parentDocumentID: String? = nil
    /// 更新のため、現在情報を保持
    private var todoData: TodoData? = nil
    private let actionType: ActionType!
    
    
    // MARK: - View Life Cycle
    
    init(todoData: TodoData) {
        self.todoData = todoData
        self.actionType = .update
        super.init(nibName: nil, bundle: nil)
    }
    
    init(parentDocumentID: String) {
        self.parentDocumentID = parentDocumentID
        self.actionType = .create
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setUpViewModel()
        setUpInitialData()
    }
    
    
    // MARK: - Action
    
    private func setUpInitialData() {
        if actionType == .update {
            guard let todoData else { return }
            deleteButton.isHidden = false
            headerLabel.text = "やること編集"
            registerButton.setTitle("更新", for: .normal)
            registerButton.addTarget(self, action: #selector(tapUpdateButton), for: .touchUpInside)
            titleTextField.text = todoData.title
            titleTextField.sendActions(for: .valueChanged)
            startDatePicker.date = todoData.startDate
            startDatePicker.sendActions(for: .valueChanged)
            endDatePicker.date = todoData.endDate
            endDatePicker.sendActions(for: .valueChanged)
            statusSegmentedControl.selectedSegmentIndex = todoData.status
            focusSwitch.setOn(todoData.isFocus, animated: false)
        } else {
            startDatePicker.sendActions(for: .valueChanged)
            endDatePicker.sendActions(for: .valueChanged)
        }
    }
    
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
                navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
        
        // オフライン時の送信待ちアラート表示
        viewModel.outputs.unsentAlertDriver
            .drive(onNext: { [weak self] in
                guard let self else { return }
                let okAction = UIAlertAction(title: "OK", style: .default) {
                    [weak self] _ in
                    self?.navigationController?.popViewController(animated: true)
                }
                present(createUnsentAlert(action: okAction), animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    @IBAction func tapRegisterButton(_ sender: Any) {
        guard let parentDocumentID else { return }
        let todoData = TodoData(title: titleTextField.text!,
                                startDate: startDatePicker.date,
                                endDate: endDatePicker.date,
                                status: statusSegmentedControl.selectedSegmentIndex)
        viewModel.saveTodoData(parentDocumentID: parentDocumentID, todoData: todoData, isFocus: focusSwitch.isOn)
    }
    
    @objc private func tapUpdateButton() {
        guard let todoData else { return }
        
        let newData = TodoData(parentDocumentID: todoData.parentDocumentID,
                               documentID: todoData.documentID,
                               title: titleTextField.text!,
                               startDate: startDatePicker.date,
                               endDate: endDatePicker.date,
                               status: statusSegmentedControl.selectedSegmentIndex,
                               isFocus: focusSwitch.isOn)
        viewModel.updateTodoData(previousFocusValue: todoData.isFocus, todoData: newData)
    }
    
    @IBAction func tapDeleteButton(_ sender: Any) {
        present(createDeleteAlert(), animated: true)
    }
    
    func createDeleteAlert() -> UIAlertController {
        let title = todoData?.title ?? ""
        let alertController = UIAlertController(title: "「\(title)」を削除してよろしいですか？", message: nil, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "はい", style: .default) {
            [weak self] _ in
            guard let self, let todoData else { return }
            viewModel.deleteTodoData(todoData: todoData)
        }
        let cancelAction = UIAlertAction(title: "いいえ", style: .cancel)
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        return alertController
    }
    
}
