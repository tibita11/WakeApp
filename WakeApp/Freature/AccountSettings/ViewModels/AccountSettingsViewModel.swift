//
//  AccountSettingsViewModel.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/06/03.
//

import Foundation
import RxSwift
import RxCocoa

struct AccountSettingsViewModelInput {
    let userNameTextFieldObserver: Observable<String?>
}

protocol AccountSettingsViewModelOutput {
    var userNameValidationDriver: Driver<String> { get }
}

protocol AccountSettingsViewModelType {
    var output: AccountSettingsViewModelOutput! { get }
    func setUp(input: AccountSettingsViewModelInput)
}

class AccountSettingsViewModel: AccountSettingsViewModelType {
    var output: AccountSettingsViewModelOutput! { self }
    private let disposeBag = DisposeBag()
    private let userNameValidationRelay = PublishRelay<String>()
    
    func setUp(input: AccountSettingsViewModelInput) {
        // UserNameバリデーションチェック
        input.userNameTextFieldObserver
            .subscribe(onNext: { [weak self] userName in
                guard let userName, let self else { return }
                let result = UserNameValidator(value: userName).validate()
                switch result {
                case .valid:
                    userNameValidationRelay.accept("")
                case .invalid(let error):
                    userNameValidationRelay.accept("\(error.localizedDescription)")
                }
            })
            .disposed(by: disposeBag)
    }
    
}


// MARK: - AccountSettingsViewModelOutput

extension AccountSettingsViewModel: AccountSettingsViewModelOutput {
    var userNameValidationDriver: Driver<String> {
        userNameValidationRelay.asDriver(onErrorDriveWith: .empty())
    }
    
}
