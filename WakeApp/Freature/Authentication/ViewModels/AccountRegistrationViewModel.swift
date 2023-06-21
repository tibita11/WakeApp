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
    var emailValidationDriver: Driver<String> { get }
    var passwordValidationDriver: Driver<String> { get }
    var registrationButtonDriver: Driver<(Bool, UIColor)> { get }
    var isLoadingDriver: Driver<Bool> { get }
    var sendCompletedDriver: Driver<Void> { get }
    var errorMessageDriver: Driver<String> { get }
    var signInCompletedDriver: Driver<Void> { get }
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
    private let emailVerification = PublishRelay<String>()
    private let dataStorage = DataStorage()
    
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

    func googleSignIn(withPresenting: UIViewController) {
        Task {
            do {
                try await GoogleAuthenticator().googleSignIn(withPresenting: withPresenting)
                signInCompleted.accept(())
            } catch (let error) {
                errorMessage.accept(error.localizedDescription)
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
                try await dataStorage.createUser(email: email, password: password)
                isLoading.accept(false)
                sendCompleted.accept(())
            } catch (let error) {
                isLoading.accept(false)
                errorMessage.accept(dataStorage.getErrorMessage(error: error))
            }
        }
    }
    
    func signIn(email: String, password: String) {
        Task {
            do {
                if try await dataStorage.signIn(email: email, password: password) {
                    signInCompleted.accept(())
                } else {
                    emailVerification.accept(email)
                }
            } catch (let error) {
                errorMessage.accept(dataStorage.getErrorMessage(error: error))
            }
        }
    }
    
    func sendEmailVerification() {
        Task {
            do {
                try await dataStorage.sendEmailVerification()
                sendCompleted.accept(())
            } catch (let error) {
                errorMessage.accept(dataStorage.getErrorMessage(error: error))
            }
        }
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
    
}


// MARK: - ASAuthorizationControllerDelegate

extension AccountRegistrationViewModel: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task {
            do {
                try await appleAuthenticator.appleSignIn(authorization: authorization)
                signInCompleted.accept(())
            } catch (let error) {
                errorMessage.accept(appleAuthenticator.getErrorMessage(error: error))
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
