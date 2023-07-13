//
//  ProfileViewModel.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/06/26.
//

import Foundation
import RxSwift
import RxCocoa

protocol ProfileViewModelOutputs {
    var nameDriver: Driver<String> { get }
    var imageUrlDriver: Driver<String> { get }
    var futureDriver: Driver<String> { get }
    var errorAlertDriver: Driver<String> { get }
    var networkErrorAlertDriver: Driver<Void> { get }
    var isHiddenErrorDriver: Driver<Bool> { get }
}

protocol ProfileViewModelType {
    var outputs: ProfileViewModelOutputs { get }
}

class ProfileViewModel: ProfileViewModelType {
    var outputs: ProfileViewModelOutputs { self }
    
    private let firebaseAuthService = FirebaseAuthService()
    private let firebaseFirestoreService = FirebaseFirestoreService()
    private var nameRelay = PublishRelay<String>()
    private let imageUrlRelay = PublishRelay<String>()
    private let futureRelay = PublishRelay<String>()
    private let errorAlertRelay = PublishRelay<String>()
    private let networkErrorAlertRelay = PublishRelay<Void>()
    /// 再試行ボタン非表示の切り替え
    private let isHiddenErrorRelay = PublishRelay<Bool>()
    private let disposeBag = DisposeBag()
    /// 初回時のみ実行するメソッドが存在するため、判別のために保持
    private var didCall = false
    
    
    // MARK: - Action
    
    /// 初期値をセット
    func getInitalData() {
        do {
            let userID = try firebaseAuthService.getCurrenUserID()
            firebaseFirestoreService.getGoalData(uid: userID)
                .subscribe(onNext: { [weak self] goalData in
                    guard let self else { return }
                    // goalDataをView側にバインド
                    
                    // UserData取得
                    if !didCall {
                        getUserData()
                    }
                    isHiddenErrorRelay.accept(true)
                    
                }, onError: { [weak self] error in
                    guard let self else { return }
                    if Network.shared.isOnline() {
                        // オンラインの場合、想定外エラー
                        errorAlertRelay.accept(Const.errorText)
                        print("Error: \(error.localizedDescription)")
                    } else {
                        // オフラインの場合、再試行ボタン
                        networkErrorAlertRelay.accept(())
                        isHiddenErrorRelay.accept(false)
                    }
                })
                .disposed(by: disposeBag)
        } catch let error {
            // UserIDが取得できない場合、再ログインを促す
            errorAlertRelay.accept(error.localizedDescription)
        }
    }
    
    /// 初回時のみ実行
    private func getUserData() {
        do {
            let userID = try firebaseAuthService.getCurrenUserID()
            firebaseFirestoreService.getUserData(uid: userID)
                .subscribe(onNext: { [weak self] userData in
                    guard let self else { return }
                    print("")
                    nameRelay.accept(userData.name)
                    imageUrlRelay.accept(userData.imageURL)
                    futureRelay.accept(userData.future)
                    // 初回時のみ
                    if !didCall {
                        didCall = true
                    }
                    
                }, onError: { [weak self] error in
                    guard let self else { return }
                    errorAlertRelay.accept(Const.errorText)
                    print("Error: \(error.localizedDescription)")
                })
                .disposed(by: disposeBag)
        } catch let error {
            // UserIDが取得できない場合、再ログインを促す
            errorAlertRelay.accept(error.localizedDescription)
        }
    }
    
}


// MARK: - ProfileViewModelOutputs

extension ProfileViewModel: ProfileViewModelOutputs {
    var nameDriver: Driver<String> {
        nameRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var imageUrlDriver: Driver<String> {
        imageUrlRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var futureDriver: Driver<String> {
        futureRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var errorAlertDriver: Driver<String> {
        errorAlertRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var networkErrorAlertDriver: Driver<Void> {
        networkErrorAlertRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var isHiddenErrorDriver: Driver<Bool> {
        isHiddenErrorRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    
}
