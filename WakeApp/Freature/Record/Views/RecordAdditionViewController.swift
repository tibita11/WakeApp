//
//  RecordAdditionViewController.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/07/19.
//

import UIKit
import RxSwift
import RxCocoa

class RecordAdditionViewController: UIViewController {

    @IBOutlet weak var datePicker: UIDatePicker! {
        didSet {
            switch actionType {
            case .create:
                datePicker.date = Date()
            case .update:
                guard let recordData else { return }
                datePicker.date = recordData.date
            default:
                break
            }
        }
    }
    @IBOutlet weak var registerButton: UIButton! {
        didSet {
            registerButton.layer.cornerRadius = Const.LargeBlueButtonCorner
            switch actionType {
            case .create:
                registerButton.addTarget(self, action: #selector(tapRegisterButton), for: .touchUpInside)
            case .update:
                registerButton.setTitle("更新", for: .normal)
                registerButton.addTarget(self, action: #selector(tapUpdateButton), for: .touchUpInside)
            default:
                break
            }
        }
    }
    @IBOutlet weak var textView: PlaceHolderTextView! {
        didSet {
            textView.placeHolder = "進捗や今の気持ちを書いてみましょう！"
        }
    }
    
    private let viewModel = RecordAdditionViewModel()
    private let disposeBag = DisposeBag()
    private let recordData: RecordData?
    private let actionType: ActionType!
    private var goalDocumentID: String?
    private var toDoDocumentID: String?
    
    
    // MARK: - View Life Cycle
    
    init(goalDocumentID: String? = nil, toDoDocumentID: String? = nil, recordData: RecordData) {
        self.recordData = recordData
        self.actionType = .update
        self.goalDocumentID = goalDocumentID
        self.toDoDocumentID = toDoDocumentID
        super.init(nibName: nil, bundle: nil)
    }
    
    init(goalDocumentID: String? = nil, toDoDocumentID: String? = nil) {
        self.recordData = nil
        self.actionType = .create
        self.goalDocumentID = goalDocumentID
        self.toDoDocumentID = toDoDocumentID
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpViewModel()
        
        if actionType == .update {
            setUpNavigationButton()
            setUpTextView()
        }
    }
    
    
    // MARK: - Action
    
    @objc private func tapUpdateButton() {
        guard let recordData else {
            assertionFailure("recordDataが存在しませんでした。")
            return
        }
        let newData = RecordData(date: datePicker.date, comment: textView.text)
        viewModel.updateRecordData(documentID: recordData.documentID, recordData: newData)
    }
    
    @objc private func tapRegisterButton(_ sender: Any) {
        guard let text = textView.text else { return }
        let data = RecordData(date: datePicker.date, comment: text)
        
        viewModel.saveRecordData(goalDocumentID: goalDocumentID,
                                 toDoDocumentID: toDoDocumentID,
                                 recordData: data)
    }
    
    private func setUpViewModel() {
        let inputs = RecordAdditionViewModelInputs(textViewObserver: textView.rx.text.asObservable())
        viewModel.setUp(inputs: inputs)
        
        viewModel.outputs.backNavigationDriver
            .drive(onNext: { [weak self] in
                guard let self else { return }
                navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
        
        viewModel.outputs.errorAlertDriver
            .drive(onNext: { [weak self] error in
                guard let self else { return }
                present(createErrorAlert(title: error), animated: true)
            })
            .disposed(by: disposeBag)
        
        viewModel.outputs.networkErrorAlertDriver
            .drive(onNext: { [weak self] in
                guard let self else { return }
                present(createNetworkErrorAlert(), animated: true)
            })
            .disposed(by: disposeBag)
        
        viewModel.outputs.isRegisterButtonEnabledDriver
            .drive(onNext: { [weak self] bool in
                guard let self else { return }
                registerButton.isEnabled = bool
                registerButton.backgroundColor = bool ? Const.mainBlueColor : .systemGray2
            })
            .disposed(by: disposeBag)
    }
    
    private func setUpNavigationButton() {
        let deleteButton = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(tapDeleteButton))
        navigationItem.rightBarButtonItem = deleteButton
    }
    
    @objc private func tapDeleteButton() {
        guard let recordData else {
            assertionFailure("recordDataが存在しませんでした。")
            return
        }
        // 確認アラートを表示する
        let alertController = UIAlertController(title: "記録を削除してよろしいですか？", message: nil, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "はい", style: .default) { [weak self] _ in
            self?.viewModel.deleteRecordData(documentID: recordData.documentID)
        }
        let cancelAction = UIAlertAction(title: "いいえ", style: .cancel)
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
    
    private func setUpTextView() {
        guard let recordData else { return }
        textView.placeHolderLabel.alpha = 0
        textView.text = recordData.comment
    }
    
}
