//
//  NewAccountRegistrationViewModel.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/05/29.
//

import UIKit
import RxSwift
import RxCocoa
import AuthenticationServices
import FirebaseAuth

struct AccountRegistrationViewModelInput {
    let emailTextFieldObserver: Observable<String?>
    let passwordTextFieldObserver: Observable<String?>
}

protocol AccountRegistrationViewModelOutput {
    var errorAlertDriver: Driver<UIAlertController> { get }
    var emailValidationDriver: Driver<String> { get }
    var passwordValidationDriver: Driver<String> { get }
    var newRegistrationButtonDriver: Driver<(Bool, UIColor)> { get }
    var transitionDriver: Driver<UIViewController> { get }
    var loadingDriver: Driver<Bool> { get }
}

protocol AccountRegistrationViewModelType {
    var output: AccountRegistrationViewModelOutput! { get }
    func setUp(input: AccountRegistrationViewModelInput)
}

class AccountRegistrationViewModel: NSObject ,AccountRegistrationViewModelType {
    var output: AccountRegistrationViewModelOutput! { self }
    private let errorAlertPublishRelay = PublishRelay<UIAlertController>()
    private lazy var appleAuthenticator: AppleAuthenticator = {
        let appleAuthenticator = AppleAuthenticator()
        return appleAuthenticator
    }()
    /// Apple認証画面を表示するために必要
    weak var viewController: UIViewController?
    private let disposeBag = DisposeBag()
    private let emailValidationRelay = BehaviorRelay(value: "入力してください。")
    private let passwordValidationRelay = BehaviorRelay(value: "入力してください。")
    private let newRegistrationButtonRelay = PublishRelay<(Bool, UIColor)>()
    private let transitionRelay = PublishRelay<UIViewController>()
    private let loadingRelay = PublishRelay<Bool>()
    
    func setUp(input: AccountRegistrationViewModelInput) {
        // Emailバリデーションチェック
        input.emailTextFieldObserver
            .subscribe(onNext: { [weak self] email in
                guard let email = email, let self = self else { return }
                
                let result = EmailValidator(value: email).validate()
                switch result {
                case .valid:
                    self.emailValidationRelay.accept("")
                case .invalid(let error):
                    self.emailValidationRelay.accept(error.localizedDescription)
                }
                self.checkButtonIsAvailable()
            })
            .disposed(by: disposeBag)
        // Passwordバリデーションチェック
        input.passwordTextFieldObserver
            .subscribe(onNext: { [weak self] password in
                guard let password = password, let self = self else { return }
                
                let result = PasswordValidator(value: password).validate()
                switch result {
                case .valid:
                    self.passwordValidationRelay.accept("")
                case .invalid(let error):
                    self.passwordValidationRelay.accept(error.localizedDescription)
                }
                self.checkButtonIsAvailable()
            })
            .disposed(by: disposeBag)
    }
    
    /// バリデーションが全てOKの場合にボタンを有効にする
    private func checkButtonIsAvailable() {
        if emailValidationRelay.value == "" && passwordValidationRelay.value == "" {
            newRegistrationButtonRelay.accept((true, Const.mainBlueColor))
        } else {
            newRegistrationButtonRelay.accept((false, UIColor.systemGray2))
        }
    }
    
    func googleSignIn(withPresenting: UIViewController) {
        Task {
            do {
                try await GoogleAuthenticator().googleSignIn(withPresenting: withPresenting)
                // 画面遷移
                let accountSettingsVC = await AccountSettingsViewController()
                transitionRelay.accept(accountSettingsVC)
            } catch (let error) {
                // アラート表示
                await MainActor.run {
                    let errorAlert = createErrorAlert(message: error.localizedDescription)
                    errorAlertPublishRelay.accept(errorAlert)
                }
            }
        }
    }
    
    private func createErrorAlert(message: String) -> UIAlertController {
        let controller = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        controller.addAction(okAction)
        return controller
    }
    
    func appleSignIn(withPresenting: UIViewController) {
        self.viewController = withPresenting
        let controller = ASAuthorizationController(authorizationRequests: [appleAuthenticator.getRequest()])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    func createUser(email: String, password: String) {
        Task {
            do {
                loadingRelay.accept(true)
                try await Auth.auth().createUser(withEmail: email, password: password)
                Auth.auth().languageCode = "ja_JP"
                try await Auth.auth().currentUser?.sendEmailVerification()
                loadingRelay.accept(false)
                // 送信画面へ遷移
                let outgoingEmailVC = await OutgoingEmailViewController()
                transitionRelay.accept(outgoingEmailVC)
            } catch(let error) {
                loadingRelay.accept(false)
                // アラート表示
                await MainActor.run {
                    let errorAlert = createErrorAlert(message: error.localizedDescription)
                    errorAlertPublishRelay.accept(errorAlert)
                }
            }
        }
    }
    
    func signIn(email: String, password: String) {
        Task {
            do {
                let result = try await Auth.auth().signIn(withEmail: email, password: password)
                if result.user.isEmailVerified {
                    // 画面遷移
                    let accountSettingsVC = await AccountSettingsViewController()
                    transitionRelay.accept(accountSettingsVC)
                } else {
                    // 認証メール送信を促すアラートを表示
                    await MainActor.run {
                        let alertController = createEmailVerificationAlert(email: email)
                        errorAlertPublishRelay.accept(alertController)
                    }
                }
            } catch(let error) {
                // アラート表示
                await MainActor.run {
                    let errorAlert = createErrorAlert(message: error.localizedDescription)
                    errorAlertPublishRelay.accept(errorAlert)
                }
            }
        }
    }
    
    /// メール認証が未完了の場合に表示するアラート
    /// - Parameter email: サインインに使用したメールアドレス
    private func createEmailVerificationAlert(email: String) -> UIAlertController {
        let alertController = UIAlertController(title: nil,
                                                message: "メール認証が完了していません。\n\(email)に認証メールを送信してよろしいですか？",
                                                preferredStyle: .alert)
        let noAction = UIAlertAction(title: "いいえ", style: .cancel)
        let yesAction = UIAlertAction(title: "送信", style: .default) { [weak self] _ in
            guard let self = self else { return }
            Task {
                do {
                    try await Auth.auth().currentUser?.sendEmailVerification()
                    // 送信画面へ遷移
                    let outgoingEmailVC = await OutgoingEmailViewController()
                    self.transitionRelay.accept(outgoingEmailVC)
                } catch(let error) {
                    // アラート表示
                    await MainActor.run {
                        let errorAlert = self.createErrorAlert(message: error.localizedDescription)
                        self.errorAlertPublishRelay.accept(errorAlert)
                    }
                }
            }
        }
        alertController.addAction(noAction)
        alertController.addAction(yesAction)
        return alertController
    }
}


// MARK: - NewAccountRegistrationViewModelOutput

extension AccountRegistrationViewModel: AccountRegistrationViewModelOutput {
    var errorAlertDriver: Driver<UIAlertController> {
        errorAlertPublishRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var emailValidationDriver: Driver<String> {
        emailValidationRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var passwordValidationDriver: Driver<String> {
        passwordValidationRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var newRegistrationButtonDriver: Driver<(Bool, UIColor)> {
        newRegistrationButtonRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var transitionDriver: Driver<UIViewController> {
        transitionRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver(onErrorJustReturn: false)
    }
    
}


// MARK: - ASAuthorizationControllerDelegate

extension AccountRegistrationViewModel: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        // Appleサインイン実行
        Task {
            do {
                try await appleAuthenticator.appleSignIn(authorization: authorization)
                // 画面遷移
                let accountSettingsVC = await AccountSettingsViewController()
                transitionRelay.accept(accountSettingsVC)
            } catch (let error) {
                // アラート表示
                await MainActor.run {
                    let errorAlert = createErrorAlert(message: error.localizedDescription)
                    errorAlertPublishRelay.accept(errorAlert)
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // アラート表示
        let errorAlert = createErrorAlert(message: error.localizedDescription)
        errorAlertPublishRelay.accept(errorAlert)
    }
}


// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AccountRegistrationViewModel: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Apple認証画面表示
        return viewController!.view.window!
    }
}
