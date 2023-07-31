//
//  GoalsEditingViewModel.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/07/03.
//

import Foundation
import RxSwift
import RxCocoa

protocol GoalsEditingViewModelOutputs {
    var goalDataDriver: Driver<[GoalData]> { get }
    var networkErrorHiddenDriver: Driver<Bool> { get }
    var errorAlertDriver: Driver<String> { get }
    var transitionToGoalRegistrationDriver: Driver<GoalData> { get }
    var transitionToTodoRegistrationDriver: Driver<(String, TodoData)> { get }
}

protocol GoalsEditingViewModelType {
    var outputs: GoalsEditingViewModelOutputs { get }
}

class GoalsEditingViewModel: GoalsEditingViewModelType {
    var outputs: GoalsEditingViewModelOutputs { self }
    
    private let firestoreService = FirebaseFirestoreService()
    private let authService = FirebaseAuthService()
    private let disposeBag = DisposeBag()
    private let goalDataRelay = BehaviorRelay<[GoalData]>(value: [])
    private let networkErrorHiddenRelay = PublishRelay<Bool>()
    private let errorAlertRelay = PublishRelay<String>()
    private let transitionToGoalRegistrationRelay = PublishRelay<GoalData>()
    private let transitionToTodoRegistrationRelay = PublishRelay<(String, TodoData)>()
    private var birthDay: Date? = nil
    private var goalData: [GoalData] = []
    
    func getInitialData() {
        getUserData()
    }
    
    private func getUserData() {
        networkErrorHiddenRelay.accept(true)
        
        do {
            let userID = try authService.getCurrenUserID()
            firestoreService.getUserData(uid: userID)
                .subscribe(onNext: { [weak self] userData in
                    guard let self else { return }
                    // オフライン時のエラーが被る可能性があるので、完了後に実行
                    getGoalData()
                    
                    birthDay = userData.birthday
                }, onError: { [weak self] error in
                    guard let self else { return }
                    if Network.shared.isOnline() {
                        errorAlertRelay.accept(Const.errorText)
                        print("Error: \(error.localizedDescription)")
                    } else {
                        networkErrorHiddenRelay.accept(false)
                    }
                })
                .disposed(by: disposeBag)
        } catch let error {
            // UserIDが取得できない場合、再ログインを促す
            errorAlertRelay.accept(error.localizedDescription)
        }
    }
    
    func getGoalData(isInitialDataFetch: Bool = true) {
        guard isInitialDataFetch || firestoreService.checkLoadStatus() else {
            return
        }
        
        networkErrorHiddenRelay.accept(true)
        
        do {
            let userID = try authService.getCurrenUserID()
            
            Task {
                do {
                    let items = try await firestoreService.getGoalData(uid: userID,
                                                                        isInitialDataFetch: isInitialDataFetch)
                    if isInitialDataFetch {
                        goalData = items
                    } else {
                        goalData.append(contentsOf: items)
                    }
                    goalDataRelay.accept(goalData)
                    
                } catch let error {
                    firestoreService.setErrorToLoadStatus()
                    
                    if Network.shared.isOnline() {
                        print("Error: \(error.localizedDescription)")
                        errorAlertRelay.accept(Const.errorText)
                    } else {
                        networkErrorHiddenRelay.accept(false)
                    }
                }
            }
        } catch let error {
            // UserIDが取得できない場合、再ログインを促す
            errorAlertRelay.accept(error.localizedDescription)
        }
    }
    
    /// 取得したItemから指定番目のドキュメントIDを取得
    ///
    /// - Parameter num: ドキュメントIDが必要な行数
    func getDocumentID(row: Int) -> String {
        let items = goalDataRelay.value
        return items[row].documentID
    }
    
    /// GoalDataを取得後に更新画面に遷移
    ///
    /// - Parameter row: Goalsコレクションのドキュメント
    func getGoalData(row: Int) {
        let items = goalDataRelay.value
        let goalData = items[row]
        transitionToGoalRegistrationRelay.accept(goalData)
    }
    
    /// TodoDataを取得後に更新画面に遷移
    ///
    /// - Parameters:
    ///   - section: Goalsコレクションのドキュメント
    ///   - row: Todosコレクションのドキュメント
    func getTodoData(section: Int, row: Int) {
        let items = goalDataRelay.value
        let parentDocumentID = items[section].documentID
        let todoData = items[section].todos[row]
        transitionToTodoRegistrationRelay.accept((parentDocumentID, todoData))
    }
    
    /// 年齢を算出する
    ///
    /// - Parameter date: 算出する日付
    ///
    /// - Returns: nilの場合は誕生日の設定がされていない
    func calculateAge(at date: Date) -> Int? {
        // 誕生日と日付から年齢を算出する処理を実行
        guard let birthDay else {
            return nil
        }
        let calender = Calendar.current
        let ageComponents = calender.dateComponents([.year], from: birthDay, to: date)
        let age = ageComponents.year ?? {
            assertionFailure("年齢計算に失敗しました。")
            return nil
        }()
        return age
    }
    
}


// MARK: - GoalsEditingViewModelOutputs

extension GoalsEditingViewModel: GoalsEditingViewModelOutputs {
    var goalDataDriver: Driver<[GoalData]> {
        goalDataRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var networkErrorHiddenDriver: Driver<Bool> {
        networkErrorHiddenRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var errorAlertDriver: Driver<String> {
        errorAlertRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var transitionToGoalRegistrationDriver: Driver<GoalData> {
        transitionToGoalRegistrationRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var transitionToTodoRegistrationDriver: Driver<(String, TodoData)> {
        transitionToTodoRegistrationRelay.asDriver(onErrorDriveWith: .empty())
    }
   
}
