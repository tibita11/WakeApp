//
//  GoalRegistrationViewModel.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/07/03.
//

import Foundation
import RxSwift
import RxCocoa

struct GoalRegistrationViewModelInputs {
    let startDatePickerObserver: Observable<Date?>
    let endDatePickerObserver: Observable<Date?>
    let titleTextFieldObserver: Observable<String?>
}

protocol GoalRegistrationViewModelOutputs {
    var errorAlertDriver: Driver<String> { get }
    var dismissScreenDriver: Driver<Void> { get }
    var dateErrorDriver: Driver<String> { get }
    var startDateTextDriver: Driver<String> { get }
    var endDateTextDriver: Driver<String> { get }
    var titleErrorDriver: Driver<String> { get }
    var registerButtonDriver: Driver<Bool> { get }
    var unsentAlertDriver: Driver<Void> { get }
}

protocol GoalRegistrationViewModelType {
    var outputs: GoalRegistrationViewModelOutputs { get }
    func setUp(inputs: GoalRegistrationViewModelInputs)
}

class GoalRegistrationViewModel: GoalRegistrationViewModelType {
    var outputs: GoalRegistrationViewModelOutputs { self }
    
    private let firestoreService = FirebaseFirestoreService()
    private let authService = FirebaseAuthService()
    private let disposeBag = DisposeBag()
    private let errorAlertRelay = PublishRelay<String>()
    private let dismissScreenRelay = PublishRelay<Void>()
    private let startDateTextRelay = PublishRelay<String>()
    private let endDateTextRelay = PublishRelay<String>()
    private let dateErrorRelay = BehaviorRelay(value: "※ 開始日・終了日は必須項目です。")
    private let titleErrorRelay = BehaviorRelay(value: "※ 目標名は必須項目です。")
    private let unsentAlertRelay = PublishRelay<Void>()
    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        return dateFormatter
    }()
    
    init() {
        
    }
    
    /// インスタンス化の際に実行する初期設定
    ///
    /// - Parameter inputs: 必須Observer
    func setUp(inputs: GoalRegistrationViewModelInputs) {
        // 終了日付が開始日付を上回る場合にエラーを表示
        Observable.combineLatest(inputs.startDatePickerObserver,
                                 inputs.endDatePickerObserver)
        .map { startDate, endDate -> String in
            if let startDate = startDate,
               let endDate = endDate,
               endDate < startDate {
                return "開始日付は終了日より前でなければいけません。"
            }
            return ""
        }
        .subscribe(onNext: { [weak self] error in
            self?.dateErrorRelay.accept(error)
        })
        .disposed(by: disposeBag)
        
        // DateをTextに変換
        inputs.startDatePickerObserver
            .subscribe(onNext: { [weak self] date in
                guard let self, let date else { return }
                startDateTextRelay.accept(dateFormatter.string(from: date))
            })
            .disposed(by: disposeBag)
        
        // DateをTextに変換
        inputs.endDatePickerObserver
            .subscribe(onNext: { [weak self] date in
                guard let self, let date else { return }
                endDateTextRelay.accept(dateFormatter.string(from: date))
            })
            .disposed(by: disposeBag)
        
        // Titleのバリデーションチェック
        inputs.titleTextFieldObserver
            .skip(2)
            .subscribe(onNext: { [weak self] title in
                guard let self, let title else { return }
                switch TitleValidator(value: title).validate() {
                case .valid:
                    titleErrorRelay.accept("")
                case .invalid(let error):
                    titleErrorRelay.accept(error.localizedDescription)
                }
            })
            .disposed(by: disposeBag)
    }
    
    /// FirestoreにGoalDataを保存
    ///
    /// - Parameter data: 保存するデータ
    func saveGoadlData(date: GoalData) {
        do {
            let userID = try authService.getCurrenUserID()
            // オフラインチェック
            if Network.shared.isOnline() {
                dismissScreenRelay.accept(())
            } else {
                unsentAlertRelay.accept(())
            }
            firestoreService.saveGoalData(uid: userID, goalData: date)
        } catch let error {
            // uidが取得できない場合、再ログインを促す
            errorAlertRelay.accept(error.localizedDescription)
        }
    }
}


// MARK: - GoalRegistrationViewModelOutputs

extension GoalRegistrationViewModel: GoalRegistrationViewModelOutputs {
    var errorAlertDriver: Driver<String> {
        errorAlertRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var dismissScreenDriver: Driver<Void> {
        dismissScreenRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var dateErrorDriver: Driver<String> {
        dateErrorRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var startDateTextDriver: Driver<String> {
        startDateTextRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var endDateTextDriver: Driver<String> {
        endDateTextRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var titleErrorDriver: Driver<String> {
        titleErrorRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var registerButtonDriver: Driver<Bool> {
        Observable.combineLatest(dateErrorRelay, titleErrorRelay)
            .map { dateError, titleError -> Bool in
                return dateError.isEmpty && titleError.isEmpty
            }
            .asDriver(onErrorDriveWith: .empty())
    }
    
    var unsentAlertDriver: Driver<Void> {
        unsentAlertRelay.asDriver(onErrorDriveWith: .empty())
    }
    
}
