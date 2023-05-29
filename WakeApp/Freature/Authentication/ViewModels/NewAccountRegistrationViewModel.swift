//
//  NewAccountRegistrationViewModel.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/05/29.
//

import UIKit
import RxSwift
import RxCocoa

protocol NewAccountRegistrationViewModelOutput {
    var errorAlertDriver: Driver<UIAlertController> { get }
}

protocol NewAccountRegistrationViewModelType {
    var output: NewAccountRegistrationViewModelOutput! { get }
}

class NewAccountRegistrationViewModel: NewAccountRegistrationViewModelType {
    var output: NewAccountRegistrationViewModelOutput! { self }
    private let errorAlertPublishRelay = PublishRelay<UIAlertController>()
    
    
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
}


// MARK: - NewAccountRegistrationViewModelOutput

extension NewAccountRegistrationViewModel: NewAccountRegistrationViewModelOutput {
    var errorAlertDriver: Driver<UIAlertController> {
        errorAlertPublishRelay.asDriver(onErrorDriveWith: .empty())
    }
    
}
