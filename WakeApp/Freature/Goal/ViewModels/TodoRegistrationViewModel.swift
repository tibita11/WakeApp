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
    var registerButtonDriver: Driver<Bool> { get }
    var errorAlertDriver: Driver<String> { get }
    var dismissDriver: Driver<Void> { get }
    var unsentAlertDriver: Driver<Void> { get }
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
    private let errorAlertRelay = PublishRelay<String>()
    private let dismissRelay = PublishRelay<Void>()
    private let unsentAlertRelay = PublishRelay<Void>()
    private let authService = FirebaseAuthService()
    private let firestoreService = FirebaseFirestoreService()
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
    
    /// TodoDataを保存
    ///
    /// - Parameters:
    ///   - documentID: Goalsコレクションに保存されているドキュメント名
    ///   - todoData: 保存するデータ
    ///   - isFocus: Focusコレクションに登録するか否か
    func saveTodoData(parentDocumentID: String, todoData: TodoData, isFocus: Bool) {
        do {
            let userID = try authService.getCurrenUserID()
            // TodoDataの保存
            let todoReference = firestoreService
                .createTodReference(uid: userID, parentDocumentID: parentDocumentID)
            firestoreService.saveTodoData(reference: todoReference, todoData: todoData)
            // FocusコレクションにTodoDataの参照先を登録
            if isFocus {
                let focusReference = firestoreService.createFocusReference(uid: userID)
                firestoreService.saveFocusData(reference: focusReference, focusData: todoReference)
            }
            checkNetwork()
        } catch let error {
           // uidが存在しない場合は、再ログインを促す
            errorAlertRelay.accept(error.localizedDescription)
        }
    }
    
    /// TodoDataを更新
    ///
    /// - Parameter todoData: 更新後のデータ
    func updateTodoData(todoData: TodoData) {
        do {
            let userID = try authService.getCurrenUserID()
            firestoreService.updateTodoData(uid: userID, todoData: todoData)
            checkNetwork()
        } catch let error {
            // uidが存在しない場合は、再ログインを促す
             errorAlertRelay.accept(error.localizedDescription)
        }
    }
    
    /// オフラインとオンラインで処理を判別
    private func checkNetwork() {
        if Network.shared.isOnline() {
            // 戻る
            dismissRelay.accept(())
        } else {
            // 送信待ちアラート
            unsentAlertRelay.accept(())
        }
    }
    
    /// TodoDataを削除
    ///
    /// - Parameter todoData: 削除するデータ
    func deleteTodoData(todoData: TodoData) {
        do {
            let userID = try authService.getCurrenUserID()
            firestoreService.deleteTodoData(uid: userID, todoData: todoData)
            checkNetwork()
        } catch let error {
            // uidが存在しない場合は、再ログインを促す
             errorAlertRelay.accept(error.localizedDescription)
        }
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
    
    var registerButtonDriver: Driver<Bool> {
        Observable.combineLatest(titleErrorTextRelay, dateErrorTextRelay)
            .map { titleError, dateError -> Bool in
                if titleError.isEmpty && dateError.isEmpty {
                    return true
                }
                return false
            }
            .asDriver(onErrorDriveWith: .empty())
    }
    
    var errorAlertDriver: Driver<String> {
        errorAlertRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var dismissDriver: Driver<Void> {
        dismissRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var unsentAlertDriver: Driver<Void> {
        unsentAlertRelay.asDriver(onErrorDriveWith: .empty())
    }
    
}
