//
//  ProfileEditingViewController.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/06/28.
//

import UIKit
import RxSwift
import RxCocoa
import Kingfisher

class ProfileEditingViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView! {
        didSet {
            imageView.layer.borderColor = UIColor.systemGray2.cgColor
            imageView.layer.borderWidth = 1.0
            imageView.layer.cornerRadius = imageView.bounds.width / 2
        }
    }
    @IBOutlet weak var imageChangeButton: UIButton! {
        didSet {
            imageChangeButton.layer.cornerRadius = 15
        }
    }
    @IBOutlet weak var registerButton: UIButton! {
        didSet {
            registerButton.layer.cornerRadius = Const.LargeBlueButtonCorner
        }
    }
    @IBOutlet weak var futureTextView: PlaceHolderTextView! {
        didSet {
            futureTextView.placeHolder = "例) たくさんの人を救える医者になりたい"
        }
    }
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var birthdayTextField: UITextField!
    @IBOutlet weak var errorTextStackView: UIStackView!
    
    private var viewModel: ProfileEditingViewModel!
    private let disposeBag = DisposeBag()
    private var datePicker = UIDatePicker()
    
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpViewModel()
        setUpDatePicker()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewModel.getUserData()
    }
    
    
    // MARK: - Action
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    private func setUpViewModel() {
        // ViewModel初期化
        let datePickerObserver = datePicker.rx.controlEvent(.valueChanged)
            .map { [weak self] in
                self?.datePicker.date
            }
        let input = ProfileEditingViewModelInputs(datePickerObserver: datePickerObserver)
        viewModel = ProfileEditingViewModel(input: input)
        // バインド
        viewModel.outputs.imageUrlDriver
            .drive(onNext: { [weak self] url in
                self?.imageView.kf.setImage(with: URL(string: url))
            })
            .disposed(by: disposeBag)
        
        viewModel.outputs.nameDriver
            .drive(nameTextField.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.outputs.birthdayDriver
            .drive(datePicker.rx.date)
            .disposed(by: disposeBag)
        
        viewModel.outputs.birthdayTextDriver
            .drive(birthdayTextField.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.outputs.futureDriver
            .drive(futureTextView.rx.text)
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
        
        viewModel.outputs.isHiddenErrorDriver
            .drive(errorTextStackView.rx.isHidden)
            .disposed(by: disposeBag)
    }
    
    private func setUpDatePicker() {
        let toolBar = UIToolbar(frame: CGRect(origin: .zero, size: CGSize(width: 100.0, height: 45.0)))
        let spaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let doneButton = UIBarButtonItem(title: "完了", style: .done, target: self, action: #selector(tapDoneButton))
        let clearButton = UIBarButtonItem(title: "クリア", style: .plain, target: self, action: #selector(tapClearButton))
        toolBar.items = [clearButton, spaceItem, doneButton]
        toolBar.sizeToFit()
        
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.datePickerMode = .date
        datePicker.locale = Locale(identifier: "ja_JP")
        
        birthdayTextField.inputView = datePicker
        birthdayTextField.inputAccessoryView = toolBar
    }
    
    /// ToolBarに設置する完了ボタン
    @objc private func tapDoneButton() {
        birthdayTextField.resignFirstResponder()
    }
    
    /// ToolBarに設置するクリアボタン
    @objc private func tapClearButton() {
        birthdayTextField.text = ""
    }

    @IBAction func tapImageChangeButton(_ sender: Any) {
        let vc = AccountImageSettingsViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func tapRetryButton(_ sender: Any) {
        viewModel.getUserData()
    }
    
    
}
