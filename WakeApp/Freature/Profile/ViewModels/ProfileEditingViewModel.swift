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
}

protocol ProfileEditingViewModelType {
    var outputs: ProfileEditingViewModelOutputs { get }
}

class ProfileEditingViewModel: ProfileEditingViewModelType {
    var outputs: ProfileEditingViewModelOutputs { self }
    
    private let disposeBag = DisposeBag()
    private let dataStorage = DataStorage()
    private let imageUrlRelay = PublishRelay<String>()
    private let nameRelay = PublishRelay<String>()
    private let birthdayRelay = PublishRelay<Date>()
    private let birthdayTextRelay = PublishRelay<String>()
    private let futureRelay = PublishRelay<String>()
    private let errorAlertRelay = PublishRelay<String>()
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
    }
    
    func getUserData() {
        Task {
            do {
                let userID = try dataStorage.getCurrenUserID()
                let userData = try await dataStorage.getUserData(uid: userID)
                
                imageUrlRelay.accept(userData.imageURL)
                nameRelay.accept(userData.name)
                futureRelay.accept(userData.future)
                
                if let birthday = userData.birthday {
                    birthdayTextRelay.accept(dateFormatter.string(from: birthday))
                    birthdayRelay.accept(birthday)
                }
            } catch let error as DataStorageError{
                errorAlertRelay.accept(error.localizedDescription)
            } catch {
                let errorText = "エラーが起きました。\nしばらくしてから再度お試しください。"
                errorAlertRelay.accept(errorText)
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
    
}
