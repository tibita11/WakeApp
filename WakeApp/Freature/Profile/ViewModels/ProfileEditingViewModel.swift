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
    var networkErrorHiddenDriver: Driver<Bool> { get }
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
    private let networkErrorHiddenRelay = PublishRelay<Bool>()
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
        // 非表示
        networkErrorHiddenRelay.accept(true)
        
        do {
            let userID = try firebaseAuthService.getCurrenUserID()
            firebaseFirestoreService.getUserData(uid: userID)
                .subscribe(onNext: { [weak self] userData in
                    guard let self else { return }
                    imageUrlRelay.accept(userData.imageURL)
                    nameRelay.accept(userData.name)
                    futureRelay.accept(userData.future)

                    if let birthday = userData.birthday {
                        birthdayTextRelay.accept(dateFormatter.string(from: birthday))
                        birthdayRelay.accept(birthday)
                    }
                    
                }, onError: { [weak self] error in
                    guard let self else { return }
                    // エラー処理
                    if Network.shared.isOnline() {
                        print("Error: \(error.localizedDescription)")
                        errorAlertRelay.accept(Const.errorText)
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
    
    func updateUserData(name: String, birthday: Date?, future: String?) {
        Task {
            do {
                let userID = try firebaseAuthService.getCurrenUserID()
                firebaseFirestoreService.updateUserData(uid: userID, name: name, birthday: birthday, future: future ?? "")
                transitionToRootViewRelay.accept(())
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
    
    var networkErrorHiddenDriver: Driver<Bool> {
        networkErrorHiddenRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var transitionToRootViewDriver: Driver<Void> {
        transitionToRootViewRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    
}
