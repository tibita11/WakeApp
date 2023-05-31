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

struct NewAccountRegistrationViewModelInput {
    let emailTextFieldObserver: Observable<String?>
    let passwordTextFieldObserver: Observable<String?>
}

protocol NewAccountRegistrationViewModelOutput {
    var errorAlertDriver: Driver<UIAlertController> { get }
    var emailValidationDriver: Driver<String> { get }
    var passwordValidationDriver: Driver<String> { get }
    var newRegistrationButtonDriver: Driver<(Bool, UIColor)> { get }
}

protocol NewAccountRegistrationViewModelType {
    var output: NewAccountRegistrationViewModelOutput! { get }
    func setUp(input: NewAccountRegistrationViewModelInput)
}

class NewAccountRegistrationViewModel: NSObject ,NewAccountRegistrationViewModelType {
    var output: NewAccountRegistrationViewModelOutput! { self }
    private let errorAlertPublishRelay = PublishRelay<UIAlertController>()
    private lazy var appleAuthenticator: AppleAuthenticator = {
        let appleAuthenticator = AppleAuthenticator()
        return appleAuthenticator
    }()
    /// Apple認証画面を表示するために必要
    weak var viewController: UIViewController?
    private let disposeBag = DisposeBag()
    private let emailValidationaBehavior = BehaviorRelay(value: "入力してください。")
    private let passwordValidationaBehavior = BehaviorRelay(value: "入力してください。")
    private let newRegistrationButtonPublish = PublishRelay<(Bool, UIColor)>()
    
    func setUp(input: NewAccountRegistrationViewModelInput) {
        // Emailバリデーションチェック
        input.emailTextFieldObserver
            .subscribe(onNext: { [weak self] email in
                guard let email = email, let self = self else { return }
                
                let result = EmailValidator(value: email).validate()
                switch result {
                case .valid:
                    self.emailValidationaBehavior.accept("")
                case .invalid(let error):
                    self.emailValidationaBehavior.accept(error.localizedDescription)
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
                    self.passwordValidationaBehavior.accept("")
                case .invalid(let error):
                    self.passwordValidationaBehavior.accept(error.localizedDescription)
                }
                self.checkButtonIsAvailable()
            })
            .disposed(by: disposeBag)
    }
    
    /// バリデーションが全てOKの場合にボタンを有効にする
    private func checkButtonIsAvailable() {
        if emailValidationaBehavior.value == "" && passwordValidationaBehavior.value == "" {
            newRegistrationButtonPublish.accept((true, Const.mainBlueColor))
        } else {
            newRegistrationButtonPublish.accept((false, UIColor.systemGray2))
        }
    }
    
    func googleSignIn(withPresenting: UIViewController) {
        Task {
            do {
                try await GoogleAuthenticator().googleSignIn(withPresenting: withPresenting)
            } catch (let error) {
                // アラート表示
                let errorAlert = createErrorAlert(message: error.localizedDescription)
                errorAlertPublishRelay.accept(errorAlert)
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
}


// MARK: - NewAccountRegistrationViewModelOutput

extension NewAccountRegistrationViewModel: NewAccountRegistrationViewModelOutput {
    var errorAlertDriver: Driver<UIAlertController> {
        errorAlertPublishRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var emailValidationDriver: Driver<String> {
        emailValidationaBehavior.asDriver(onErrorDriveWith: .empty())
    }
    
    var passwordValidationDriver: Driver<String> {
        passwordValidationaBehavior.asDriver(onErrorDriveWith: .empty())
    }
    
    var newRegistrationButtonDriver: Driver<(Bool, UIColor)> {
        newRegistrationButtonPublish.asDriver(onErrorDriveWith: .empty())
    }
    
    
}


// MARK: - ASAuthorizationControllerDelegate

extension NewAccountRegistrationViewModel: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        // Appleサインイン実行
        Task {
            do {
                try await appleAuthenticator.appleSignIn(authorization: authorization)
            } catch (let error) {
                // アラート表示
                let errorAlert = createErrorAlert(message: error.localizedDescription)
                errorAlertPublishRelay.accept(errorAlert)
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

extension NewAccountRegistrationViewModel: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Apple認証画面表示
        return viewController!.view.window!
    }
}
