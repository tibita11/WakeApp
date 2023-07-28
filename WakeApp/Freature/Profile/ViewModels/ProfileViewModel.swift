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
    var goalDataDriver: Driver<[GoalData]> { get }
    var networkErrorHiddenDriver: Driver<Bool> { get }
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
    private let disposeBag = DisposeBag()
    /// 初回時のみ実行するメソッドが存在するため、判別のために保持
    private var didCall = false
    private let goalDataRelay = PublishRelay<[GoalData]>()
    private var birthDay: Date? = nil
    private let networkErrorHiddenRelay = PublishRelay<Bool>()
    
    
    // MARK: - Action
    
    func getInitalData() {
        if didCall {
            // 初回以降はGoalDataのみ
            getGoalData()
        } else {
            // 初回の場合はUserDataとGoalDataを取得
            getUserData()
        }
    }
    
    private func getGoalData() {
        // 非表示
        networkErrorHiddenRelay.accept(true)
        
        do {
            let userID = try firebaseAuthService.getCurrenUserID()
            firebaseFirestoreService.getGoalData(uid: userID)
                .subscribe(onNext: { [weak self] goalData in
                    guard let self else { return }
                    // goalDataをView側にバインド
                    goalDataRelay.accept(goalData)
                    
                }, onError: { [weak self] error in
                    guard let self else { return }
                    if Network.shared.isOnline() {
                        print("Error: \(error.localizedDescription)")
                        errorAlertRelay.accept(Const.errorText)
                    } else {
                        print("オフラインエラー")
                        networkErrorHiddenRelay.accept(false)
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
        networkErrorHiddenRelay.accept(true)
        
        do {
            let userID = try firebaseAuthService.getCurrenUserID()
            firebaseFirestoreService.getUserData(uid: userID)
                .subscribe(onNext: { [weak self] userData in
                    guard let self else { return }
                    // オフライン時のエラーが被る可能性があるので、完了後に実行
                    getGoalData()
                    
                    nameRelay.accept(userData.name)
                    imageUrlRelay.accept(userData.imageURL)
                    futureRelay.accept(userData.future)
                    birthDay = userData.birthday
                    // 初回時のみ
                    if !didCall {
                        didCall = true
                    }
                    
                }, onError: { [weak self] error in
                    guard let self else { return }
                    if Network.shared.isOnline() {
                        print("Error: \(error.localizedDescription)")
                        errorAlertRelay.accept(Const.errorText)
                    } else {
                        print("オフラインエラー")
                        networkErrorHiddenRelay.accept(false)
                    }
                })
                .disposed(by: disposeBag)
        } catch let error {
            // UserIDが取得できない場合、再ログインを促す
            errorAlertRelay.accept(error.localizedDescription)
        }
    }
    
    /// 年齢を算出する
    ///
    /// - Parameter date: 算出する日付
    ///
    /// - Returns: nilの場合は誕生日の設定がされていない
    func calculateAge(at date: Date) -> Int? {
        // 誕生日と日付から年齢を算出する処理を実行
        guard let birthDay else {
            return nil
        }
        let calender = Calendar.current
        let ageComponents = calender.dateComponents([.year], from: birthDay, to: date)
        let age = ageComponents.year ?? {
            assertionFailure("年齢計算に失敗しました。")
            return nil
        }()
        return age
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
    
    var goalDataDriver: Driver<[GoalData]> {
        goalDataRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var networkErrorHiddenDriver: Driver<Bool> {
        networkErrorHiddenRelay.asDriver(onErrorDriveWith: .empty())
    }
    
}
