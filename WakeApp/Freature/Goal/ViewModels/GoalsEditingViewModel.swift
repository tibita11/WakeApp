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
    var isHiddenErrorDriver: Driver<Bool> { get }
    var networkErrorDriver: Driver<Void> { get }
    var errorAlertDriver: Driver<String> { get }
    var transitionToGoalRegistrationDriver: Driver<GoalData> { get }
    var transitionToTodoRegistrationDriver: Driver<TodoData> { get }
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
    private let isHiddenErrorRelay = PublishRelay<Bool>()
    private let networkErrorRelay = PublishRelay<Void>()
    private let errorAlertRelay = PublishRelay<String>()
    private let transitionToGoalRegistrationRelay = PublishRelay<GoalData>()
    private let transitionToTodoRegistrationRelay = PublishRelay<TodoData>()
    
    init() {

    }
    
    
    func getGoalData() {
        // オフラインチェック
        if Network.shared.isOnline() {
            isHiddenErrorRelay.accept(true)
        } else {
            networkErrorRelay.accept(())
            isHiddenErrorRelay.accept(false)
        }
        
        do {
            let userID = try authService.getCurrenUserID()
            firestoreService.getGoalData(uid: userID)
                .subscribe(onNext: { [weak self] goalData in
                    // goadDataをView側に通知
                    self?.goalDataRelay.accept(goalData)
                }, onError: { [weak self] error in
                    print("Error: \(error.localizedDescription)")
                    // アラート表示
                    self?.errorAlertRelay.accept(Const.errorText)
                })
                .disposed(by: disposeBag)
        } catch let error {
            // アラート表示
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
        let todoData = items[section].todos[row]
        transitionToTodoRegistrationRelay.accept(todoData)
    }
    
}


// MARK: - GoalsEditingViewModelOutputs

extension GoalsEditingViewModel: GoalsEditingViewModelOutputs {
    var goalDataDriver: Driver<[GoalData]> {
        goalDataRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var isHiddenErrorDriver: Driver<Bool> {
        isHiddenErrorRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var networkErrorDriver: Driver<Void> {
        networkErrorRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var errorAlertDriver: Driver<String> {
        errorAlertRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var transitionToGoalRegistrationDriver: Driver<GoalData> {
        transitionToGoalRegistrationRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var transitionToTodoRegistrationDriver: Driver<TodoData> {
        transitionToTodoRegistrationRelay.asDriver(onErrorDriveWith: .empty())
    }
   
}
