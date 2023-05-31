//
//  NewAccountRegistrationViewController.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/05/29.
//

import UIKit
import RxSwift
import RxCocoa

class NewAccountRegistrationViewController: UIViewController {

    @IBOutlet weak var newRegistrationButton: UIButton! {
        didSet {
            newRegistrationButton.layer.cornerRadius = Const.LargeBlueButtonCorner
        }
    }
    @IBOutlet weak var googleRegistrationButton: UIButton! {
        didSet {
            googleRegistrationButton.layer.cornerRadius = Const.LargeBlueButtonCorner
            googleRegistrationButton.layer.borderColor = UIColor.black.cgColor
            googleRegistrationButton.layer.borderWidth = 1.0
        }
    }
    @IBOutlet weak var appleRegistrationButton: UIButton! {
        didSet {
            appleRegistrationButton.layer.cornerRadius = Const.LargeBlueButtonCorner
        }
    }
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var emailValidationLabel: UILabel!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var passwordValidationLabel: UILabel!
    private let viewModel = NewAccountRegistrationViewModel()
    private let disposeBag = DisposeBag()
    /// サインアップボタンとセットするアイコンを紐付け
    private lazy var iconArray: [(iconName: String, setButton: UIButton)] = {
       let iconArray = [
        ("AppleIcon", appleRegistrationButton!),
        ("GoogleIcon", googleRegistrationButton!)]
        return iconArray
    }()
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUp()
    }
    
    
    // MARK: - Action
    
    @IBAction func tapGoogleRegistrationButton(_ sender: Any) {
        viewModel.googleSignIn(withPresenting: self)
    }
    
    @IBAction func tapAppleRegistrationButton(_ sender: Any) {
        viewModel.appleSignIn(withPresenting: self)
    }
    
    private func setUp() {
        setUpButtonIcon()
        // viewModel設定
        let input = NewAccountRegistrationViewModelInput(emailTextFieldObserver: emailTextField.rx.text.asObservable(),
                                                         passwordTextFieldObserver: passwordTextField.rx.text.asObservable())
        viewModel.setUp(input: input)
        // エラーアラート表示
        viewModel.output.errorAlertDriver
            .drive(onNext: { [weak self] alert in
                self?.present(alert, animated: true)
            })
            .disposed(by: disposeBag)
        // テキストとバインド
        viewModel.output.emailValidationDriver
            .skip(2)
            .drive(emailValidationLabel.rx.text)
            .disposed(by: disposeBag)
        // テキストとバインド
        viewModel.output.passwordValidationDriver
            .skip(2)
            .drive(passwordValidationLabel.rx.text)
            .disposed(by: disposeBag)
        // 登録ボタンの色、状態を変更する
        viewModel.output.newRegistrationButtonDriver
            .drive(onNext: { [weak self] (bool, color) in
                self?.newRegistrationButton.isEnabled = bool
                self?.newRegistrationButton.backgroundColor = color
            })
            .disposed(by: disposeBag)
    }
    
    /// サインアップボタンにアイコンをセットする
    private func setUpButtonIcon() {
        iconArray.forEach {
            let image = UIImage(named: $0.iconName)
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
            imageView.image = image
            imageView.layer.cornerRadius = imageView.bounds.width / 2
            imageView.layer.masksToBounds = true
            $0.setButton.addSubview(imageView)
        }
    }

}
