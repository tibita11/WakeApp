//
//  ProfileSettingsTableViewModel.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/07/27.
//

import Foundation
import RxSwift
import RxCocoa

protocol ProfileSettingsTableViewModelOutputs {
    var networkErrorAlertDriver: Driver<Void> { get }
    var errorAlertDriver: Driver<String> { get }
    var navigateToStartingViewDriver: Driver<Void> { get }
}

protocol ProfileSettingsTableViewModelType {
    var outputs: ProfileSettingsTableViewModelOutputs { get }
}

class ProfileSettingsTableViewModel: ProfileSettingsTableViewModelType {
    var outputs: ProfileSettingsTableViewModelOutputs { self }
    
    private let authService = FirebaseAuthService()
    private let networkErrorAlertRelay = PublishRelay<Void>()
    private let errorAlertRelay = PublishRelay<String>()
    private let navigateToStartingViewRelay = PublishRelay<Void>()
    private lazy var snsLinkManager: SNSLinkManager = {
        return SNSLinkManager()
    }()
    
    func unsubscribe() {
        Task {
            do {
                try await authService.unsubscribe()
                navigateToStartingViewRelay.accept(())
            } catch let error {
                if Network.shared.isOnline() {
                    // 再ログインを促す
                    print("Error: \(error.localizedDescription)")
                    errorAlertRelay.accept(Const.reLogain)
                } else {
                    networkErrorAlertRelay.accept(())
                }
            }
        }
    }
    
    func signOut() {
        do {
            try authService.signOut()
            navigateToStartingViewRelay.accept(())
        } catch let error {
            print("Error: \(error.localizedDescription)")
            errorAlertRelay.accept(Const.errorText)
        }
    }
    
    func transitionToTwitter() {
        snsLinkManager.transitionToTwitter()
    }
}


// MARK: - ProfileSettingsTableViewModelOutputs

extension ProfileSettingsTableViewModel: ProfileSettingsTableViewModelOutputs {
    var networkErrorAlertDriver: Driver<Void> {
        networkErrorAlertRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var errorAlertDriver: Driver<String> {
        errorAlertRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var navigateToStartingViewDriver: Driver<Void> {
        navigateToStartingViewRelay.asDriver(onErrorDriveWith: .empty())
    }
}
