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
    private let isHiddenErrorRelay = PublishRelay<Bool>()
    private let networkErrorRelay = PublishRelay<Void>()
    
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
                }, onError: { error in
                    // オフラインチェック
                    if Network.shared.isOnline() {
                        if let error = error as? FirebaseFirestoreServiceError {
                            // データが存在しない
                            // 目標を追加することを促すViewを表示
                            print("データが存在しません。")
                        } else {
                            // 不明なエラー
                            // エラーが起きたことを通知する
                            // それと一緒にやり直せる環境（再試行ボタン）は表示する
                            assertionFailure("Error: GoalDataの読み込み失敗")
                        }
                    } else {
                        // 再試行ボタンをUI側に通知
                        print("オフライン")
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
    
    var isHiddenErrorDriver: Driver<Bool> {
        isHiddenErrorRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var networkErrorDriver: Driver<Void> {
        networkErrorRelay.asDriver(onErrorDriveWith: .empty())
    }
   
}
