//
//  ProfileEditingViewModel.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/06/28.
//

import Foundation
import RxSwift
import RxCocoa

struct ProfileEditingViewModelInputs {
    let datePickerObserver: Observable<Date?>
}

protocol ProfileEditingViewModelOutputs {
    var imageUrlDriver: Driver<String> { get }
    var nameDriver: Driver<String> { get }
    var birthdayDriver: Driver<Date> { get }
    var birthdayTextDriver: Driver<String> { get }
    var futureDriver: Driver<String> { get }
    var errorAlertDriver: Driver<String> { get }
    var networkErrorAlertDriver: Driver<Void> { get }
    var isHiddenErrorDriver: Driver<Bool> { get }
    var unsentAlertDriver: Driver<Void> { get }
    var transitionToRootViewDriver: Driver<Void> { get }
}

protocol ProfileEditingViewModelType {
    var outputs: ProfileEditingViewModelOutputs { get }
}

class ProfileEditingViewModel: ProfileEditingViewModelType {
    var outputs: ProfileEditingViewModelOutputs { self }
    
    private let disposeBag = DisposeBag()
    private let firebaseAuthService = FirebaseAuthService()
    private let firebaseFirestoreService = FirebaseFirestoreService()
    private let imageUrlRelay = PublishRelay<String>()
    private let nameRelay = PublishRelay<String>()
    private let birthdayRelay = PublishRelay<Date>()
    private let birthdayTextRelay = PublishRelay<String>()
    private let futureRelay = PublishRelay<String>()
    private let errorAlertRelay = PublishRelay<String>()
    private let networkErrorAlertRelay = PublishRelay<Void>()
    private let isHiddenError = PublishRelay<Bool>()
    private let unsentAlertRelay = PublishRelay<Void>()
    private let transitionToRootViewRelay = PublishRelay<Void>()
    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        return dateFormatter
    }()
    
    init(input: ProfileEditingViewModelInputs) {
        input.datePickerObserver
            .subscribe(onNext: { [weak self] date in
                guard let date, let self else { return }
                birthdayTextRelay.accept(dateFormatter.string(from: date))
            })
            .disposed(by: disposeBag)
        
        getUserData()

    }
    
    /// UserDataの取得
    func getUserData() {
        // 初期値を設定
        do {
            let userID = try firebaseAuthService.getCurrenUserID()
            firebaseFirestoreService.getUserData(uid: userID)
                .subscribe(onNext: { [weak self] userData in
                    guard let self else { return }
                    // UIに反映
                    imageUrlRelay.accept(userData.imageURL)
                    nameRelay.accept(userData.name)
                    futureRelay.accept(userData.future)

                    if let birthday = userData.birthday {
                        birthdayTextRelay.accept(dateFormatter.string(from: birthday))
                        birthdayRelay.accept(birthday)
                    }
                    // 再試行画面の非表示
                    isHiddenError.accept(true)
                }, onError: { [weak self] error in
                    guard let self else { return }
                    // エラー処理
                    if Network.shared.isOnline() {
                        // エラーが出た場合は、コード側のミス
                        print("Error: \(error.localizedDescription)")
                        let errorText = "エラーが起きました。\nしばらくしてから再度お試しください。"
                        errorAlertRelay.accept(errorText)
                        // 再試行画面の表示
                        isHiddenError.accept(false)
                    } else {
                        // オフライン
                        networkErrorAlertRelay.accept(())
                        isHiddenError.accept(false)
                    }

                })
                .disposed(by: disposeBag)

        } catch let error {
            // UserIDが取得できない場合、再ログインを促す
            errorAlertRelay.accept(error.localizedDescription)
        }
    }
    
    func updateUserData(name: String, birthday: Date?, future: String?) {
        Task {
            do {
                let userID = try firebaseAuthService.getCurrenUserID()
                firebaseFirestoreService.updateUserData(uid: userID, name: name, birthday: birthday, future: future ?? "")
                
                if Network.shared.isOnline() {
                    // オンラインの場合、画面遷移
                    transitionToRootViewRelay.accept(())
                } else {
                    // オフラインの場合、アラート表示
                    unsentAlertRelay.accept(())
                }
            } catch let error as FirebaseAuthServiceError {
                // 再ログイン促す
                errorAlertRelay.accept(error.localizedDescription)
            }
        }
    }
}


// MARK: - ProfileEditingViewModelOutputs

extension ProfileEditingViewModel: ProfileEditingViewModelOutputs {
    var imageUrlDriver: Driver<String> {
        imageUrlRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var nameDriver: Driver<String> {
        nameRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var birthdayDriver: Driver<Date> {
        birthdayRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var birthdayTextDriver: Driver<String> {
        birthdayTextRelay.asDriver(onErrorDriveWith: .empty())
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
        isHiddenError.asDriver(onErrorDriveWith: .empty())
    }
    
    var unsentAlertDriver: Driver<Void> {
        unsentAlertRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var transitionToRootViewDriver: Driver<Void> {
        transitionToRootViewRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    
}
