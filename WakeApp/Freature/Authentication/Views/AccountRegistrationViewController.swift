//
//  NewAccountRegistrationViewController.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/05/29.
//

import UIKit
import RxSwift
import RxCocoa

class AccountRegistrationViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.text = self.registrationStatus.title
        }
    }
    @IBOutlet weak var registrationButton: UIButton! {
        didSet {
            registrationButton.layer.cornerRadius = Const.LargeBlueButtonCorner
            registrationButton.setTitle(self.registrationStatus.title, for: .normal)
            // 新規とサインインで処理を分ける
            switch registrationStatus {
            case .newAccount:
                registrationButton.addTarget(self,
                                             action: #selector(tapRegistrationButton),
                                             for: .touchUpInside)
            case .existingAccount:
                registrationButton.addTarget(self,
                                             action: #selector(tapSignInButton),
                                             for: .touchUpInside)
            }
        }
    }
    @IBOutlet weak var googleRegistrationButtonContainerView: UIView! {
        didSet {
            googleRegistrationButtonContainerView.layer.cornerRadius = Const.LargeBlueButtonCorner
            googleRegistrationButtonContainerView.layer.masksToBounds = true
            googleRegistrationButtonContainerView.layer.borderColor = UIColor.black.cgColor
            googleRegistrationButtonContainerView.layer.borderWidth = 1.0
        }
    }
    @IBOutlet weak var googleRegistrationButtonLabel: UILabel! {
        didSet {
            googleRegistrationButtonLabel.text = "Googleで\(self.registrationStatus.authenticationButtonTitle)"
        }
    }
    @IBOutlet weak var appleRegistrationButtonContainerView: UIView! {
        didSet {
            appleRegistrationButtonContainerView.layer.cornerRadius = Const.LargeBlueButtonCorner
            appleRegistrationButtonContainerView.layer.masksToBounds = true
        }
    }
    @IBOutlet weak var appleRegistrationButtonLabel: UILabel! {
        didSet {
            appleRegistrationButtonLabel.text = "Appleで\(self.registrationStatus.authenticationButtonTitle)"
        }
    }
    @IBOutlet weak var googleRegistrationButton: UIButton!
    @IBOutlet weak var appleRegistrationButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var emailValidationLabel: UILabel!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var passwordValidationLabel: UILabel!
    @IBOutlet weak var agreementStackView: UIStackView! {
        didSet {
            // サインインの場合表示しない
            agreementStackView.isHidden = self.registrationStatus == .existingAccount
        }
    }
    private let viewModel = AccountRegistrationViewModel()
    private let disposeBag = DisposeBag()
    /// DB処理中に表示する
    private lazy var loadingView: LoadingView = {
        let loadingView = LoadingView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height))
        return loadingView
    }()
    /// 新規とサインインで処理を分けるため、値を保持する
    private let registrationStatus: RegistrationStatus
    
    
    // MARK: - View Life Cycle
    
    init(status: RegistrationStatus) {
        self.registrationStatus = status
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUp()
    }
    
    
    // MARK: - Action
    
    @objc func tapRegistrationButton() {
        guard let email = emailTextField.text, let password = passwordTextField.text else {
            return
        }
        viewModel.createUser(email: email, password: password)
    }
    
    @objc func tapSignInButton() {
        guard let email = emailTextField.text, let password = passwordTextField.text else {
            return
        }
        viewModel.signIn(email: email, password: password)
    }
    
    @IBAction func tapGoogleRegistrationButton(_ sender: Any) {
        viewModel.googleSignIn(withPresenting: self)
    }
    
    @IBAction func tapAppleRegistrationButton(_ sender: Any) {
        viewModel.appleSignIn(withPresenting: self)
    }
    
    private func setUp() {
        // viewModel設定
        let input = AccountRegistrationViewModelInput(emailTextFieldObserver: emailTextField.rx.text.asObservable(),
                                                         passwordTextFieldObserver: passwordTextField.rx.text.asObservable())
        viewModel.setUp(input: input)
        // エラーアラート表示
        viewModel.output.errorAlertDriver
            .drive(onNext: { [weak self] alert in
                self?.present(alert, animated: true)
            })
            .disposed(by: disposeBag)
        
        viewModel.output.emailValidationDriver
            .skip(2)
            .drive(emailValidationLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.output.passwordValidationDriver
            .skip(2)
            .drive(passwordValidationLabel.rx.text)
            .disposed(by: disposeBag)
        // 登録ボタンの色、状態を変更する
        viewModel.output.newRegistrationButtonDriver
            .drive(onNext: { [weak self] (bool, color) in
                self?.registrationButton.isEnabled = bool
                self?.registrationButton.backgroundColor = color
            })
            .disposed(by: disposeBag)
        // 遷移処理を実行する
        viewModel.output.transitionDriver
            .drive(onNext: { [weak self] viewController in
                self?.navigationController?.pushViewController(viewController, animated: true)
            })
            .disposed(by: disposeBag)
        // ローディング画面表示
        viewModel.output.loadingDriver
            .drive(onNext: { [weak self] bool in
                self?.changeLoading(bool: bool)
            })
            .disposed(by: disposeBag)
    }
    
    /// ローディング画面の表示非表示を切り替える
    private func changeLoading(bool: Bool) {
        if bool {
            navigationController?.isNavigationBarHidden = true
            view.endEditing(true)
            loadingView.indicatorView.startAnimating()
            view.addSubview(loadingView)
        } else {
            navigationController?.isNavigationBarHidden = false
            loadingView.indicatorView.stopAnimating()
            loadingView.removeFromSuperview()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }

}


// MARK: - RegistrationStatus

enum RegistrationStatus {
    case newAccount
    case existingAccount
    
    var title: String {
        switch self {
        case .newAccount:
            return "新規登録"
        case .existingAccount:
            return "サインイン"
        }
    }
    
    var authenticationButtonTitle: String {
        switch self {
        case .newAccount:
            return "サインアップ"
        case .existingAccount:
            return "サインイン"
        }
    }
    
}
