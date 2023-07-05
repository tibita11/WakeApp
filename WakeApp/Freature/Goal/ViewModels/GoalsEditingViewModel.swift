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
}

protocol GoalsEditingViewModelType {
    var outputs: GoalsEditingViewModelOutputs { get }
}

class GoalsEditingViewModel: GoalsEditingViewModelType {
    var outputs: GoalsEditingViewModelOutputs { self }
    
    private let firestoreService = FirebaseFirestoreService()
    private let authService = FirebaseAuthService()
    private let disposeBag = DisposeBag()
    private let goalDataRelay = PublishRelay<[GoalData]>()
    
    init() {
        getGoalData()
    }
    
    private func getGoalData() {
        do {
            let userID = try authService.getCurrenUserID()
            firestoreService.getGoalData(uid: userID)
                .subscribe(onNext: { [weak self] goalData in
                    // goadDataをView側に通知
                    self?.goalDataRelay.accept(goalData)
                }, onError: { error in
                    // オフラインチェック
                    if Network.shared.isOnline() {
                        if let error = error as? FirebaseFirestoreServiceError {
                            // データが存在しない
                            // 目標を追加することを促すViewを表示
                            
                        } else {
                            // 不明なエラー
                            // エラーが起きたことを通知する
                            // それと一緒にやり直せる環境（再試行ボタン）は表示する
                            assertionFailure("Error: GoalDataの読み込み失敗")
                        }
                    } else {
                        // 再試行ボタンをUI側に通知
                        
                    }
                })
                .disposed(by: disposeBag)
        } catch {
            
        }
    }
}


// MARK: - GoalsEditingViewModelOutputs

extension GoalsEditingViewModel: GoalsEditingViewModelOutputs {
    var goalDataDriver: Driver<[GoalData]> {
        goalDataRelay.asDriver(onErrorDriveWith: .empty())
    }
    
}
