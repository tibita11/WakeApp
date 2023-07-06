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
}

protocol GoalRegistrationViewModelOutputs {
    var errorAlertDriver: Driver<String> { get }
    var dismissScreenDriver: Driver<Void> { get }
    var dateErrorDriver: Driver<String> { get }
    var startDateTextDriver: Driver<String> { get }
    var endDateTextDriver: Driver<String> { get }
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
    private let dateErrorRelay = PublishRelay<String>()
    private let startDateTextRelay = PublishRelay<String>()
    private let endDateTextRelay = PublishRelay<String>()
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
               endDate > startDate {
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
    }
    
    /// FirestoreにGoalDataを保存
    ///
    /// - Parameter data: 保存するデータ
    func saveGoadlData(date: GoalData) {
        do {
            let userID = try authService.getCurrenUserID()
            // 画面を閉じる
            dismissScreenRelay.accept(())
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

}
