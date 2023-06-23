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
        
        // Emailバリデーション
        viewModel.output.emailValidationDriver
            .drive(emailValidationLabel.rx.text)
            .disposed(by: disposeBag)
        
        // Passwordバリデーション
        viewModel.output.passwordValidationDriver
            .drive(passwordValidationLabel.rx.text)
            .disposed(by: disposeBag)
        
        // 登録ボタンの色、状態
        viewModel.output.registrationButtonDriver
            .drive(onNext: { [weak self] (bool, color) in
                self?.registrationButton.isEnabled = bool
                self?.registrationButton.backgroundColor = color
            })
            .disposed(by: disposeBag)
        
        // 送信完了画面への遷移
        viewModel.output.sendCompletedDriver
            .drive(onNext: { [weak self] in
                guard let self else { return }
                let vc = OutgoingEmailViewController()
                navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: disposeBag)
        
        // エラーアラート表示
        viewModel.output.errorMessageDriver
            .drive(onNext: { [weak self] error in
                guard let self else { return }
                present(createErrorAlert(title: error), animated: true)
            })
            .disposed(by: disposeBag)
        
        // ローディング画面表示
        viewModel.output.isLoadingDriver
            .drive(onNext: { [weak self] bool in
                self?.changeLoading(bool: bool)
            })
            .disposed(by: disposeBag)
        
        // 記録画面へ遷移
        viewModel.output.signInCompletedDriver
            .drive(onNext: { [weak self] in
                guard let self else { return }
                let vc = MainTabBarController()
                navigationController?.viewControllers = [vc]
            })
            .disposed(by: disposeBag)
        
        // アカウント設定画面への遷移
        viewModel.output.accountSettingsDriver
            .drive(onNext: { [weak self] in
                guard let self else { return }
                let vc = AccountSettingsViewController()
                navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: disposeBag)
        
        // Email認証アラート表示
        viewModel.output.emailVerificationDriver
            .drive(onNext: { [weak self] email in
                guard let self else { return }
                present(createEmailVerificatioinAlert(email: email), animated: true)
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
    
    private func createEmailVerificatioinAlert(email: String) -> UIAlertController {
        let alertController = UIAlertController(title: nil,
                                                message: "メール認証が完了していません。\n\(email)に認証メールを送信してよろしいですか？",
                                                preferredStyle: .alert)
        let noAction = UIAlertAction(title: "いいえ", style: .cancel)
        let yesAction = UIAlertAction(title: "送信", style: .default) { [weak self] _ in
            guard let self else { return }
            viewModel.sendEmailVerification()
        }
        alertController.addAction(noAction)
        alertController.addAction(yesAction)
        return alertController
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


// MARK: - UIViewController

extension UIViewController {
    func createErrorAlert(title: String) -> UIAlertController {
        let controller = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        controller.addAction(okAction)
        return controller
    }
}
