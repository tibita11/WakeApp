//
//  GoalRegistrationViewModel.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/07/03.
//

import Foundation
import RxSwift
import RxCocoa

protocol GoalRegistrationViewModelOutputs {
    var errorAlertDriver: Driver<String> { get }
    var dismissScreenDriver: Driver<Void> { get }
}

protocol GoalRegistrationViewModelType {
    var outputs: GoalRegistrationViewModelOutputs { get }
}

class GoalRegistrationViewModel: GoalRegistrationViewModelType {
    var outputs: GoalRegistrationViewModelOutputs { self }
    
    private let firestoreService = FirebaseFirestoreService()
    private let authService = FirebaseAuthService()
    private let errorAlertRelay = PublishRelay<String>()
    private let dismissScreenRelay = PublishRelay<Void>()
    
    init() {
        
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
    
}
