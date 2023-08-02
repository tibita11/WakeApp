//
//  RecordAdditionViewModel.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/07/19.
//

import Foundation
import RxSwift
import RxCocoa
import FirebaseFirestore

struct RecordAdditionViewModelInputs {
    let textViewObserver: Observable<String?>
}

protocol RecordAdditionViewModelOutputs {
    var backNavigationDriver: Driver<Void> { get }
    var errorAlertDriver: Driver<String> { get }
    var networkErrorAlertDriver: Driver<Void> { get }
    var isRegisterButtonEnabledDriver: Driver<Bool> { get }
}

protocol RecordAdditionViewModelType {
    var outputs: RecordAdditionViewModelOutputs { get }
    func setUp(inputs: RecordAdditionViewModelInputs)
}

class RecordAdditionViewModel: RecordAdditionViewModelType {
    var outputs: RecordAdditionViewModelOutputs { self }
    
    private let disposeBag = DisposeBag()
    private let authService = FirebaseAuthService()
    private let firestoreService = FirebaseFirestoreService()
    private let backNavigationRelay = PublishRelay<Void>()
    private let errorAlertRelay = PublishRelay<String>()
    private let networkErrorAlertRelay = PublishRelay<Void>()
    private let isRegisterButtonEnabledRelay = PublishRelay<Bool>()
    
    func setUp(inputs: RecordAdditionViewModelInputs) {
        inputs.textViewObserver
            .subscribe(onNext: { [weak self] text in
                guard let self, let text else { return }

                switch TitleValidator(value: text).validate() {
                case .valid:
                    isRegisterButtonEnabledRelay.accept(true)
                case .invalid:
                    isRegisterButtonEnabledRelay.accept(false)
                }
            })
            .disposed(by: disposeBag)
    }
    
    func getToDoReference(goalDocumentID: String?, toDoDocumentID: String?) async throws -> DocumentReference? {
        let userID = try authService.getCurrenUserID()
        if let goalDocumentID, let toDoDocumentID {
            return firestoreService.createTodoReference(uid: userID,
                                                        parentDocumentID: goalDocumentID,
                                                        documentID: toDoDocumentID)
        } else {
            let focusReference = firestoreService.createFocusReference(uid: userID)
            return try await firestoreService.getFocusData(reference: focusReference)
        }
    }
    
    func saveRecordData(goalDocumentID: String?, toDoDocumentID: String?, recordData: RecordData) {
        Task {
            do {
                guard let toDoReference = try await getToDoReference(goalDocumentID: goalDocumentID,
                                                                     toDoDocumentID: toDoDocumentID) else {
                    errorAlertRelay.accept(Const.errorText)
                    return
                }
                firestoreService.saveRecordData(toDoReference: toDoReference, recordData: recordData)
                backNavigationRelay.accept(())
                
            } catch let error as FirebaseAuthServiceError {
                // uidが取得できない場合、再ログインを促す
                errorAlertRelay.accept(error.localizedDescription)
            } catch let error {
                if Network.shared.isOnline() {
                    print("Error: \(error.localizedDescription)")
                    errorAlertRelay.accept(Const.errorText)
                } else {
                    networkErrorAlertRelay.accept(())
                }
            }
        }
    }
    
    func updateRecordData(goalDocumentID: String?, toDoDocumentID: String?, documentID: String, recordData: RecordData) {
        Task {
            do {
                guard let toDoReference = try await getToDoReference(goalDocumentID: goalDocumentID,
                                                                     toDoDocumentID: toDoDocumentID) else {
                    errorAlertRelay.accept(Const.errorText)
                    return
                }
                let recordReference = firestoreService.createRecordReference(toDoReference: toDoReference,
                                                                             documentID: documentID)
                firestoreService.updateRecordData(recordReference: recordReference, recordData: recordData)
                backNavigationRelay.accept(())
                
            } catch let error as FirebaseAuthServiceError {
                // uidが取得できない場合、再ログインを促す
                errorAlertRelay.accept(error.localizedDescription)
            } catch let error {
                if Network.shared.isOnline() {
                    print("Error: \(error.localizedDescription)")
                    errorAlertRelay.accept(Const.errorText)
                } else {
                    networkErrorAlertRelay.accept(())
                }
            }
        }
    }
    
    func deleteRecordData(goalDocumentID: String?, toDoDocumentID: String?, documentID: String) {
        Task {
            do {
                guard let toDoReference = try await getToDoReference(goalDocumentID: goalDocumentID,
                                                                     toDoDocumentID: toDoDocumentID) else {
                    errorAlertRelay.accept(Const.errorText)
                    return
                }
                let recordReference = firestoreService.createRecordReference(toDoReference: toDoReference,
                                                                             documentID: documentID)
                firestoreService.deleteRecordData(recordReference: recordReference)
                backNavigationRelay.accept(())
                
            } catch let error as FirebaseAuthServiceError {
                // uidが取得できない場合、再ログインを促す
                errorAlertRelay.accept(error.localizedDescription)
            } catch let error {
                if Network.shared.isOnline() {
                    print("Error: \(error.localizedDescription)")
                    errorAlertRelay.accept(Const.errorText)
                } else {
                    networkErrorAlertRelay.accept(())
                }
            }
        }
    }
}


// MARK: - RecordAdditionViewModelOutputs

extension RecordAdditionViewModel: RecordAdditionViewModelOutputs {
    var backNavigationDriver: Driver<Void> {
        backNavigationRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var errorAlertDriver: Driver<String> {
        errorAlertRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var networkErrorAlertDriver: Driver<Void> {
        networkErrorAlertRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var isRegisterButtonEnabledDriver: Driver<Bool> {
        isRegisterButtonEnabledRelay.asDriver(onErrorDriveWith: .empty())
    }
    
}
