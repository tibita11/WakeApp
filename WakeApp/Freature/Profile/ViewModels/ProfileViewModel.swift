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
}

protocol ProfileViewModelType {
    var outputs: ProfileViewModelOutputs { get }
}

class ProfileViewModel: ProfileViewModelType {
    var outputs: ProfileViewModelOutputs { self }
    
    private let dataStorage = DataStorage()
    private let firebaseAuthService = FirebaseAuthService()
    private var nameRelay = PublishRelay<String>()
    private let imageUrlRelay = PublishRelay<String>()
    private let futureRelay = PublishRelay<String>()
    private let errorAlertRelay = PublishRelay<String>()

    
    func getUserData() {
        Task {
            do {
                let userID = try firebaseAuthService.getCurrenUserID()
                let userData = try await dataStorage.getUserData(uid: userID)
                nameRelay.accept(userData.name)
                imageUrlRelay.accept(userData.imageURL)
                futureRelay.accept(userData.future)
                
            } catch let error as DataStorageError {
                errorAlertRelay.accept(error.localizedDescription)
            } catch {
                let errorText = "エラーが起きました。\nしばらくしてから再度お試しください。"
                errorAlertRelay.accept(errorText)
            }
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
    
}
