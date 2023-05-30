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

protocol NewAccountRegistrationViewModelOutput {
    var errorAlertDriver: Driver<UIAlertController> { get }
}

protocol NewAccountRegistrationViewModelType {
    var output: NewAccountRegistrationViewModelOutput! { get }
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
