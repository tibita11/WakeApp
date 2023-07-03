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
    private let isHiddenErrorRelay = PublishRelay<Bool>()
    private let disposeBag = DisposeBag()
    
    
    // MARK: - Action
    
    init() {
        getUserData()
    }
    
    func getUserData() {
        do {
            let userID = try firebaseAuthService.getCurrenUserID()
            firebaseFirestoreService.getUserData(uid: userID)
                .subscribe(onNext: { [weak self] userData in
                    guard let self else { return }
                    nameRelay.accept(userData.name)
                    imageUrlRelay.accept(userData.imageURL)
                    futureRelay.accept(userData.future)
                    // 再試行ボタン非表示
                    isHiddenErrorRelay.accept(true)
                }, onError: { [weak self] error in
                    guard let self else { return }
                    // エラー処理
                    if Network.shared.isOnline() {
                        // エラーが出た場合は、コード側のミス
                        print("Error: \(error.localizedDescription)")
                        let errorText = "エラーが起きました。\nしばらくしてから再度お試しください。"
                        errorAlertRelay.accept(errorText)
                        // 再試行ボタン表示
                        isHiddenErrorRelay.accept(false)
                    } else {
                        // オフライン
                        networkErrorAlertRelay.accept(())
                        // 再試行ボタン表示
                        isHiddenErrorRelay.accept(false)
                    }
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
