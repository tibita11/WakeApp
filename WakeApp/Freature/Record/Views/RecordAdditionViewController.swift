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
            if actionType == .update {
                registerButton.setTitle("更新", for: .normal)
                registerButton.addTarget(self, action: #selector(tapUpdateButton), for: .touchUpInside)
            }
        }
    }
    @IBOutlet weak var textView: PlaceHolderTextView! {
        didSet {
            textView.placeHolder = "進捗や今の気持ちを書いてみましょう！"
            if actionType == .update {
                guard let recordData else { return }
                textView.placeHolderLabel.alpha = 0
                textView.text = recordData.comment
            }
        }
    }
    
    private let viewModel = RecordAdditionViewModel()
    private let disposeBag = DisposeBag()
    private let recordData: RecordData?
    private let actionType: ActionType!
    
    
    // MARK: - View Life Cycle
    
    init(recordData: RecordData) {
        self.recordData = recordData
        self.actionType = .update
        super.init(nibName: nil, bundle: nil)
    }
    
    init() {
        self.recordData = nil
        self.actionType = .create
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpViewModel()
    }
    
    
    // MARK: - Action
    
    @objc private func tapUpdateButton() {

    }
    
    @IBAction func tapRegisterButton(_ sender: Any) {
        guard let text = textView.text else { return }
        let data = RecordData(date: datePicker.date, comment: text)
        viewModel.saveRecordData(recordData: data)
    }
    
    private func setUpViewModel() {
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
    }
    
}
