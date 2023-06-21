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
    var birthdayTextDriver: Driver<String> { get }
    var nextButtonDriver: Driver<(Bool, UIColor)> { get }
}

protocol AccountSettingsViewModelType {
    var output: AccountSettingsViewModelOutput! { get }
    func setUp(input: AccountSettingsViewModelInput)
}

class AccountSettingsViewModel: AccountSettingsViewModelType {
    var output: AccountSettingsViewModelOutput! { self }
    private let disposeBag = DisposeBag()
    private let userNameValidation = PublishRelay<String>()
    private let birthdayText = PublishRelay<String>()
    private lazy var dateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        return dateFormatter
    }()
    
    func setUp(input: AccountSettingsViewModelInput) {
        // UserNameバリデーションチェック
        input.userNameTextFieldObserver
            .subscribe(onNext: { [weak self] userName in
                guard let userName, let self else { return }
                var validation = ""
                switch UserNameValidator(value: userName).validate() {
                case .valid:
                    break
                case .invalid (let error):
                    validation = error.localizedDescription
                }
                userNameValidation.accept(validation)
            })
            .disposed(by: disposeBag)
        
        // dateをString型で表示する
        input.datePickerObserver
            .subscribe(onNext: { [weak self] date in
                guard let self, let date else {
                    return
                }
                let dateString = dateFormatter.string(from: date)
                birthdayText.accept(dateString)
            })
            .disposed(by: disposeBag)
        
    }
    
}


// MARK: - AccountSettingsViewModelOutput

extension AccountSettingsViewModel: AccountSettingsViewModelOutput {
    var userNameValidationDriver: Driver<String> {
        userNameValidation.asDriver(onErrorDriveWith: .empty())
    }
    
    var birthdayTextDriver: Driver<String> {
        birthdayText.asDriver(onErrorDriveWith: .empty())
    }
    
    var nextButtonDriver: Driver<(Bool, UIColor)> {
        return userNameValidation
            .map {
                if $0.isEmpty {
                    return (true, Const.mainBlueColor)
                } else {
                    return (false, UIColor.systemGray2)
                }
            }
            .asDriver(onErrorDriveWith: .empty())
    }
    
}
