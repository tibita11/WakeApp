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
    let startDatePickerObserver: Observable<Date?>
    let endDatePickerObserver: Observable<Date?>
}

protocol TodoRegistrationViewModelOutputs {
    var titleErrorTextDriver: Driver<String> { get }
    var startDateTextDriver: Driver<String> { get }
    var endDateTextDriver: Driver<String> { get }
    var dateErrorTextDriver: Driver<String> { get }
}

protocol TodoRegistrationViewModelType {
    var outputs: TodoRegistrationViewModelOutputs { get }
    func setUp(inputs: TodoRegistrationViewModelInputs)
}

class TodoRegistrationViewModel: TodoRegistrationViewModelType {
    var outputs: TodoRegistrationViewModelOutputs { self }
    
    private let disposeBag = DisposeBag()
    private let titleErrorTextRelay = PublishRelay<String>()
    private let startDateTextRelay = PublishRelay<String>()
    private let endDateTextRelay = PublishRelay<String>()
    private let dateErrorTextRelay = PublishRelay<String>()
    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        return dateFormatter
    }()
    
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
        
        // 終了日付が開始日付よりも小さい場合はエラーを返す
        Observable.combineLatest(inputs.startDatePickerObserver, inputs.endDatePickerObserver)
            .map { startDate, endDate -> String in
                if let startDate, let endDate, startDate > endDate {
                    return "開始日付は終了日より前でなければいけません。"
                }
                return ""
            }
            .subscribe(onNext: { [weak self] error in
                self?.dateErrorTextRelay.accept(error)
            })
            .disposed(by: disposeBag)
        
        // 開始日付をテキストに変換
        inputs.startDatePickerObserver
            .subscribe(onNext: { [weak self] date in
                guard let self, let date else { return }
                startDateTextRelay.accept(dateFormatter.string(from: date))
            })
            .disposed(by: disposeBag)
        
        // 終了日付をテキストに変換
        inputs.endDatePickerObserver
            .subscribe(onNext: { [weak self] date in
                guard let self, let date else { return }
                endDateTextRelay.accept(dateFormatter.string(from: date))
            })
            .disposed(by: disposeBag)
    }
    
}


// MARK: - TodoRegistrationViewModelOutputs

extension TodoRegistrationViewModel: TodoRegistrationViewModelOutputs {
    var titleErrorTextDriver: Driver<String> {
        titleErrorTextRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var startDateTextDriver: Driver<String> {
        startDateTextRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var endDateTextDriver: Driver<String> {
        endDateTextRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var dateErrorTextDriver: Driver<String> {
        dateErrorTextRelay.asDriver(onErrorDriveWith: .empty())
    }
    
}
