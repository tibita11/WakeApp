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
    @IBOutlet weak var networkErrorView: UIView! {
        didSet {
            let view = NetworkErrorView()
            view.delegate = self
            view.translatesAutoresizingMaskIntoConstraints = false
            networkErrorView.addSubview(view)
            
            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: networkErrorView.topAnchor),
                view.leftAnchor.constraint(equalTo: networkErrorView.leftAnchor),
                view.rightAnchor.constraint(equalTo: networkErrorView.rightAnchor),
                view.bottomAnchor.constraint(equalTo: networkErrorView.bottomAnchor)
            ])
        }
    }
    
    private var viewModel: ProfileEditingViewModel!
    private let disposeBag = DisposeBag()
    private var datePicker = UIDatePicker()
    
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpViewModel()
        setUpDatePicker()
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
            .drive(onNext: { [weak self] future in
                guard let self else { return }
                if !future.isEmpty {
                    futureTextView.placeHolderLabel.alpha = 0
                    futureTextView.text = future
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.outputs.errorAlertDriver
            .drive(onNext: { [weak self] error in
                guard let self else { return }
                present(createErrorAlert(title: error), animated: true)
            })
            .disposed(by: disposeBag)
        
        viewModel.outputs.networkErrorHiddenDriver
            .drive(networkErrorView.rx.isHidden)
            .disposed(by: disposeBag)
        
        // 登録時の処理
        viewModel.outputs.transitionToRootViewDriver
            .drive(onNext: { [weak self] in
                guard let self else { return }
                navigationController?.popToRootViewController(animated: true)
            })
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
    
    @IBAction func tapRegisterButton(_ sender: Any) {
        guard let name = nameTextField.text else {
            return
        }
        
        var birthday: Date? = nil
        if let birthdayText = birthdayTextField.text, !birthdayText.isEmpty {
            birthday = datePicker.date
        }
        
        let future = futureTextView.text
        
        viewModel.updateUserData(name: name, birthday: birthday, future: future)
    }
    
}


// MARK: - NetworkErrorViewDelegate

extension ProfileEditingViewController: NetworkErrorViewDelegate {
    func retryAction() {
        viewModel.getUserData()
    }
}


extension UIViewController {
    
    /// オフライン時の未送信アラート
    ///
    /// - Parameter okAction: OKボタン
    func createUnsentAlert(action: UIAlertAction) -> UIAlertController {
        let alertController = UIAlertController(title: "送信待ち保存",
                                                message: "サーバーと通信できないため、送信待ちとして保存しました。オンラインになると自動的に送信されます。",
                                                preferredStyle: .alert)
        alertController.addAction(action)
        return alertController
    }
}
