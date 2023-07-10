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
    func getDocumentID(num: Int) -> String {
        let items = goalDataRelay.value
        return items[num].documentID
    }
    
    /// 指定したドキュメントIDのGoalData取得
    ///
    /// - Parameter documentID: 取得するドキュメント名
    func getGoalData(documentID: String) {
        do {
            let userID = try authService.getCurrenUserID()
            firestoreService.getGoalData(uid: userID, documentID: documentID)
                .subscribe(onNext: { [weak self] goalData in
                    // 取得後は遷移
                    self?.transitionToGoalRegistrationRelay.accept(goalData)
                }, onError: { [weak self] error in
                    // エラーは遷移せずにアラート表示
                    if Network.shared.isOnline() {
                        // 一律でアラートを表示する
                        print("Error: \(error.localizedDescription)")
                        self?.errorAlertRelay.accept(Const.errorText)
                    } else {
                        // オフライン
                        print("Error: \(error.localizedDescription)")
                        self?.networkErrorRelay.accept(())
                    }
                })
                .disposed(by: disposeBag)
        } catch let error {
            // uidが取得できない場合は、再ログインを促す
            errorAlertRelay.accept(error.localizedDescription)
        }
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
   
}
