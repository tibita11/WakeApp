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
    
    private var viewModel: GoalRegistrationViewModel!
    private let disposeBag = DisposeBag()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUp()
    }

    
    // MARK: - Action
    
    private func setUp() {
        viewModel = GoalRegistrationViewModel()
        
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
        
    }
    
    /// Firestoreに保存
    @IBAction func tapRegistrationButton(_ sender: Any) {
        guard let title = titleTextField.text else {
            return
        }
        
        let goalData = GoalData(title: title)
        viewModel.saveGoadlData(date: goalData)
    }
}
