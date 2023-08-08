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
import GoogleSignIn

struct AccountRegistrationViewModelInput {
    let emailTextFieldObserver: Observable<String?>
    let passwordTextFieldObserver: Observable<String?>
}

protocol AccountRegistrationViewModelOutput {
    var emailValidationDriver: Driver<String> { get }
    var passwordValidationDriver: Driver<String> { get }
    var registrationButtonDriver: Driver<(Bool, UIColor)> { get }
    var isLoadingDriver: Driver<Bool> { get }
    var sendCompletedDriver: Driver<Void> { get }
    var errorMessageDriver: Driver<String> { get }
    var signInCompletedDriver: Driver<Void> { get }
    var accountSettingsDriver: Driver<Void> { get }
    var emailVerificationDriver: Driver<String> { get }
}

protocol AccountRegistrationViewModelType {
    var output: AccountRegistrationViewModelOutput! { get }
    func setUp(input: AccountRegistrationViewModelInput)
}

class AccountRegistrationViewModel: NSObject, AccountRegistrationViewModelType {
    var output: AccountRegistrationViewModelOutput! { self }
    private lazy var appleAuthenticator: AppleAuthenticator = {
        return AppleAuthenticator()
    }()
    /// Apple認証画面を表示するために必要
    weak var viewController: UIViewController?
    private let disposeBag = DisposeBag()
    private let emailValidation = PublishRelay<String>()
    private let passwordValidation = PublishRelay<String>()
    private let isLoading = PublishRelay<Bool>()
    private let sendCompleted = PublishRelay<Void>()
    private let errorMessage = PublishRelay<String>()
    private let signInCompleted = PublishRelay<Void>()
    private let accountSettings = PublishRelay<Void>()
    private let emailVerification = PublishRelay<String>()
    private let firebaseAuthService = FirebaseAuthService()
    private lazy var snsLinkManager: SNSLinkManager = {
       return SNSLinkManager()
    }()
    
    func setUp(input: AccountRegistrationViewModelInput) {
        // Emailバリデーションチェック
        input.emailTextFieldObserver
            .subscribe(onNext: { [weak self] email in
                guard let email, let self else { return }
                
                var validation = ""
                switch EmailValidator(value: email).validate() {
                case .valid:
                    break
                case .invalid (let error):
                    validation = error.localizedDescription
                }
                self.emailValidation.accept(validation)
            })
            .disposed(by: disposeBag)
        
        // Passwordバリデーションチェック
        input.passwordTextFieldObserver
            .subscribe(onNext: { [weak self]  password in
                guard let password, let self else { return }
                
                var validation = ""
                switch PasswordValidator(value: password).validate() {
                case .valid:
                    break
                case .invalid (let error):
                    validation = error.localizedDescription
                }
                self.passwordValidation.accept(validation)
            })
            .disposed(by: disposeBag)
        
    }
    
    /// - Parameter uid: ドキュメント有無で遷移先を決定
    private func determineNextScreen(from uid: String) {
        Task {
            do {
                if try await FirebaseFirestoreService().checkDocument(uid: uid) {
                    signInCompleted.accept(())
                } else {
                    accountSettings.accept(())
                }
            } catch {
                accountSettings.accept(())
            }
        }
    }

    func googleSignIn(withPresenting: UIViewController) {
        let googleAuthenticator = GoogleAuthenticator()
        Task {
            do {
                let credential = try await googleAuthenticator.googleSignIn(withPresenting: withPresenting)
                let result = try await firebaseAuthService.signIn(with: credential)
                determineNextScreen(from: result.user.uid)
            } catch let error as GIDSignInError {
                errorMessage.accept(googleAuthenticator.getErrorMessage(error: error))
            } catch let error {
                errorMessage.accept(firebaseAuthService.getErrorMessage(error: error))
            }
        }
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
                isLoading.accept(true)
                try await Task.sleep(nanoseconds: 1_500_000_000)
                try await firebaseAuthService.createUser(email: email, password: password)
                isLoading.accept(false)
                sendCompleted.accept(())
            } catch (let error) {
                isLoading.accept(false)
                errorMessage.accept(firebaseAuthService.getErrorMessage(error: error))
            }
        }
    }
    
    func signIn(email: String, password: String) {
        Task {
            do {
                let result = try await firebaseAuthService.signIn(email: email, password: password)
                guard result.user.isEmailVerified else {
                    emailVerification.accept(email)
                    return
                }
                determineNextScreen(from: result.user.uid)
            } catch (let error) {
                errorMessage.accept(firebaseAuthService.getErrorMessage(error: error))
            }
        }
    }
    
    func sendEmailVerification() {
        Task {
            do {
                try await firebaseAuthService.sendEmailVerification()
                sendCompleted.accept(())
            } catch (let error) {
                errorMessage.accept(firebaseAuthService.getErrorMessage(error: error))
            }
        }
    }
    
    func transitionToPrivacyPolicy() {
        snsLinkManager.transitionToPrivacyPolicy()
    }
    
    func transitionToTermsOfService() {
        snsLinkManager.transitionToTermsOfService()
    }
    
}


// MARK: - NewAccountRegistrationViewModelOutput

extension AccountRegistrationViewModel: AccountRegistrationViewModelOutput {
    var emailValidationDriver: Driver<String> {
        emailValidation.asDriver(onErrorDriveWith: .empty())
    }
    
    var passwordValidationDriver: Driver<String> {
        passwordValidation.asDriver(onErrorDriveWith: .empty())
    }

    var registrationButtonDriver: Driver<(Bool, UIColor)> {
        return Observable.combineLatest(emailValidation, passwordValidation)
            .map { emailValidation, passwordValidation in
                if emailValidation.isEmpty && passwordValidation.isEmpty {
                    return (true, Const.mainBlueColor)
                } else {
                    return (false, UIColor.systemGray2)
                }
            }
            .asDriver(onErrorDriveWith: .empty())
    }
    
    var isLoadingDriver: Driver<Bool> {
        isLoading.asDriver(onErrorJustReturn: false)
    }
    
    var sendCompletedDriver: Driver<Void> {
        sendCompleted.asDriver(onErrorDriveWith: .empty())
    }
    
    var errorMessageDriver: Driver<String> {
        errorMessage.asDriver(onErrorDriveWith: .empty())
    }
    
    var signInCompletedDriver: Driver<Void> {
        signInCompleted.asDriver(onErrorDriveWith: .empty())
    }
    
    var emailVerificationDriver: Driver<String> {
        emailVerification.asDriver(onErrorDriveWith: .empty())
    }
    
    var accountSettingsDriver: Driver<Void> {
        accountSettings.asDriver(onErrorDriveWith: .empty())
    }
    
}


// MARK: - ASAuthorizationControllerDelegate

extension AccountRegistrationViewModel: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task {
            do {
                let credential = appleAuthenticator.appleSignIn(authorization: authorization)
                let result = try await firebaseAuthService.signIn(with: credential)
                determineNextScreen(from: result.user.uid)
            } catch let error as ASAuthorizationError {
                errorMessage.accept(appleAuthenticator.getErrorMessage(error: error))
            } catch let error {
                errorMessage.accept(firebaseAuthService.getErrorMessage(error: error))
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        errorMessage.accept(appleAuthenticator.getErrorMessage(error: error))
    }
}


// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AccountRegistrationViewModel: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Apple認証画面表示
        return viewController!.view.window!
    }
}
