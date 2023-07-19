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

    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var registerButton: UIButton! {
        didSet {
            registerButton.layer.cornerRadius = Const.LargeBlueButtonCorner
        }
    }
    @IBOutlet weak var textView: PlaceHolderTextView! {
        didSet {
            textView.placeHolder = "進捗や今の気持ちを書いてみましょう！"
        }
    }
    
    private let viewModel = RecordAdditionViewModel()
    private let disposeBag = DisposeBag()
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpViewModel()
    }
    
    
    // MARK: - Action
    
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
