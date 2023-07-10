//
//  TodoRegistrationViewModel.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/07/10.
//

import Foundation
import RxSwift
import RxCocoa

struct TodoRegistrationViewModelInputs {
    let titleTextFieldObserver: Observable<String?>
}

protocol TodoRegistrationViewModelOutputs {
    var titleErrorTextDeriver: Driver<String> { get }
}

protocol TodoRegistrationViewModelType {
    var outputs: TodoRegistrationViewModelOutputs { get }
    func setUp(inputs: TodoRegistrationViewModelInputs)
}

class TodoRegistrationViewModel: TodoRegistrationViewModelType {
    var outputs: TodoRegistrationViewModelOutputs { self }
    
    private let disposeBag = DisposeBag()
    private let titleErrorTextRelay = PublishRelay<String>()
    
    func setUp(inputs: TodoRegistrationViewModelInputs) {
        // Titleのバリデーションチェック
        inputs.titleTextFieldObserver
            .skip(1)
            .subscribe(onNext: { [weak self] title in
                guard let self, let title else { return }
                
                switch TitleValidator(value: title).validate() {
                case .valid:
                    titleErrorTextRelay.accept("")
                case .invalid (let error):
                    titleErrorTextRelay.accept(error.localizedDescription)
                }
            })
            .disposed(by: disposeBag)
    }
    
}


// MARK: - TodoRegistrationViewModelOutputs

extension TodoRegistrationViewModel: TodoRegistrationViewModelOutputs {
    var titleErrorTextDeriver: Driver<String> {
        titleErrorTextRelay.asDriver(onErrorDriveWith: .empty())
    }
    
}
