//
//  TodoRegistrationViewModel.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/07/10.
//

import Foundation
import RxSwift
import RxCocoa
import GoogleMobileAds

struct TodoRegistrationViewModelInputs {
    let titleTextFieldObserver: Observable<String?>
    let startDatePickerObserver: Observable<Date?>
    let endDatePickerObserver: Observable<Date?>
}

protocol TodoRegistrationViewModelOutputs {
    var titleErrorTextDriver: Driver<String> { get }
    var dateErrorTextDriver: Driver<String> { get }
    var registerButtonDriver: Driver<Bool> { get }
    var errorAlertDriver: Driver<String> { get }
    var dismissDriver: Driver<Void> { get }
}

protocol TodoRegistrationViewModelType {
    var outputs: TodoRegistrationViewModelOutputs { get }
    func setUp(inputs: TodoRegistrationViewModelInputs)
}

class TodoRegistrationViewModel: TodoRegistrationViewModelType {
    var outputs: TodoRegistrationViewModelOutputs { self }
    
    private let disposeBag = DisposeBag()
    private let titleErrorTextRelay = PublishRelay<String>()
    private let dateErrorTextRelay = PublishRelay<String>()
    private let errorAlertRelay = PublishRelay<String>()
    private let dismissRelay = PublishRelay<Void>()
    private let authService = FirebaseAuthService()
    private let firestoreService = FirebaseFirestoreService()
    private(set) var interstitial: GADInterstitialAd?
    
    init() {
        if !UserDefaults.standard.bool(forKey: Const.userDefaultKeyForPurchase) {
            guard let adUinitID = Bundle.main.object(forInfoDictionaryKey: "AD_UNIT_ID") as? String else {
                assertionFailure("環境変数を取得できませんでした。")
                return
            }
            
            let request = GADRequest()
            GADInterstitialAd.load(withAdUnitID: adUinitID,
                                   request: request,
                                   completionHandler: { [self] ad, error in
                if let error = error {
                    print("Failed to load interstitial ad with error: \(error.localizedDescription)")
                    return
                }
                interstitial = ad
            })
        }
    }
        
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
            dismissRelay.accept(())
        } catch let error {
           // uidが存在しない場合は、再ログインを促す
            errorAlertRelay.accept(error.localizedDescription)
        }
    }
    
    func updateTodoData(parentDocumentID: String, previousFocusValue: Bool, todoData: TodoData) {
        do {
            let userID = try authService.getCurrenUserID()
            // TodoData更新
            let todoReference = firestoreService.createTodoReference(uid: userID,
                                                                     parentDocumentID: parentDocumentID,
                                                                     documentID: todoData.documentID)
            firestoreService.updateTodoData(reference: todoReference, todoData: todoData)
            // 変更に応じてFocusコレクション更新
            if previousFocusValue != todoData.isFocus {
                let focusReference = firestoreService.createFocusReference(uid: userID)
                if todoData.isFocus {
                    // 更新処理
                    firestoreService.saveFocusData(reference: focusReference, focusData: todoReference)
                } else {
                    // 削除処理
                    firestoreService.deleteFocusData(reference: focusReference)
                }
            }
            dismissRelay.accept(())
        } catch let error {
            // uidが存在しない場合は、再ログインを促す
             errorAlertRelay.accept(error.localizedDescription)
        }
    }
    
    /// TodoDataを削除
    ///
    /// - Parameter todoData: 削除するデータ
    func deleteTodoData(parentDocumentID: String, todoData: TodoData) {
        do {
            let userID = try authService.getCurrenUserID()
            firestoreService.deleteTodoData(uid: userID,
                                            parentDocumentID: parentDocumentID,
                                            todoData: todoData)
            dismissRelay.accept(())
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
}
