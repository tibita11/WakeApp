//
//  AccountSettingsViewModel.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/06/03.
//

import UIKit
import RxSwift
import RxCocoa

struct AccountSettingsViewModelInput {
    let userNameTextFieldObserver: Observable<String?>
    let datePickerObserver: Observable<Date?>
}

protocol AccountSettingsViewModelOutput {
    var userNameValidationDriver: Driver<String> { get }
    var birthdayTextFieldDriver: Driver<String> { get }
}

protocol AccountSettingsViewModelType {
    var output: AccountSettingsViewModelOutput! { get }
    func setUp(input: AccountSettingsViewModelInput)
}

class AccountSettingsViewModel: AccountSettingsViewModelType {
    var output: AccountSettingsViewModelOutput! { self }
    private let disposeBag = DisposeBag()
    private let userNameValidationRelay = PublishRelay<String>()
    private let birthdayTextFieldRelay = PublishRelay<String>()
    private lazy var dateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        return dateFormatter
    }()
    
    func setUp(input: AccountSettingsViewModelInput) {
        // UserNameバリデーションチェック
        input.userNameTextFieldObserver
            .skip(2)
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
        // dateをString型で表示する
        input.datePickerObserver
            .subscribe(onNext: { [weak self] date in
                guard let self else { return }
                guard let date else {
                    birthdayTextFieldRelay.accept("")
                    return
                }
                let dateString = dateFormatter.string(from: date)
                birthdayTextFieldRelay.accept(dateString)
            })
            .disposed(by: disposeBag)
    }
    
}


// MARK: - AccountSettingsViewModelOutput

extension AccountSettingsViewModel: AccountSettingsViewModelOutput {
    var userNameValidationDriver: Driver<String> {
        userNameValidationRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var birthdayTextFieldDriver: Driver<String> {
        birthdayTextFieldRelay.asDriver(onErrorDriveWith: .empty())
    }
    
}
