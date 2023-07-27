//
//  RecordAdditionViewModel.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/07/19.
//

import Foundation
import RxSwift
import RxCocoa

protocol RecordAdditionViewModelOutputs {
    var backNavigationDriver: Driver<Void> { get }
    var errorAlertDriver: Driver<String> { get }
    var networkErrorAlertDriver: Driver<Void> { get }
}

protocol RecordAdditionViewModelType {
    var outputs: RecordAdditionViewModelOutputs { get }
}

class RecordAdditionViewModel: RecordAdditionViewModelType {
    var outputs: RecordAdditionViewModelOutputs { self }
    
    private let authService = FirebaseAuthService()
    private let firestoreService = FirebaseFirestoreService()
    private let backNavigationRelay = PublishRelay<Void>()
    private let errorAlertRelay = PublishRelay<String>()
    private let networkErrorAlertRelay = PublishRelay<Void>()
    
    /// Focusコレクションに登録されているTodoに登録
    ///
    /// - Parameter recordData: 保存データ
    func saveRecordData(recordData: RecordData) {
        do {
            let userID = try authService.getCurrenUserID()
            let focusReference = firestoreService.createFocusReference(uid: userID)
            Task {
                do {
                    let toDoReference = try await firestoreService.getFocusData(reference: focusReference)
                    
                    if let toDoReference {
                        // 参照先が取ってこれた場合のみ保存
                        firestoreService.saveRecordData(toDoReference: toDoReference, recordData: recordData)
                    } else {
                        assertionFailure("ToDo参照先の取得に失敗しました。")
                    }
                    // 前の画面に戻る
                    backNavigationRelay.accept(())
                    
                } catch let error {
                    if Network.shared.isOnline() {
                        print("Error: \(error.localizedDescription)")
                        errorAlertRelay.accept(Const.errorText)
                    } else {
                        networkErrorAlertRelay.accept(())
                    }
                }
            }
        } catch let error {
            // uidが取得できない場合は、再ログインを促す
            errorAlertRelay.accept(error.localizedDescription)
        }
    }
    
    /// - Parameters:
    ///   - documentID: 更新するドキュメントID
    ///   - recordData: 更新データ
    func updateRecordData(documentID: String, recordData: RecordData) {
        do {
            // Focusコレクションのデータを取得して、recordData参照先を取得する
            let userID = try authService.getCurrenUserID()
            let focusReference = firestoreService.createFocusReference(uid: userID)
            Task {
                do {
                    guard let toDoReference = try await firestoreService.getFocusData(reference: focusReference) else {
                        assertionFailure("focusDataが存在しませんでした。")
                        return
                    }
                    let recordReference = firestoreService.createRecordReference(toDoReference: toDoReference,
                                                                                 documentID: documentID)
                    firestoreService.updateRecordData(recordReference: recordReference, recordData: recordData)
                    backNavigationRelay.accept(())
                } catch let error {
                    if Network.shared.isOnline() {
                        print("Error: \(error.localizedDescription)")
                        errorAlertRelay.accept(Const.errorText)
                    } else {
                        networkErrorAlertRelay.accept(())
                    }
                }
            }
        } catch let error {
            // uidが取得できない場合、再ログインを促す
            errorAlertRelay.accept(error.localizedDescription)
        }
    }
    
    /// - Parameter documentID: 削除するドキュメントID
    func deleteRecordData(documentID: String) {
        do {
            // Focusコレクションのデータを取得して、recordData参照先を取得する
            let userID = try authService.getCurrenUserID()
            let focusReference = firestoreService.createFocusReference(uid: userID)
            Task {
                do {
                    guard let toDoReference = try await firestoreService.getFocusData(reference: focusReference) else {
                        assertionFailure("focusDataが存在しませんでした。")
                        return
                    }
                    let recordReference = firestoreService.createRecordReference(toDoReference: toDoReference,
                                                                                 documentID: documentID)
                    firestoreService.deleteRecordData(recordReference: recordReference)
                    backNavigationRelay.accept(())
                } catch {
                    if Network.shared.isOnline() {
                        print("Error: \(error.localizedDescription)")
                        errorAlertRelay.accept(Const.errorText)
                    } else {
                        networkErrorAlertRelay.accept(())
                    }
                }
            }
        } catch let error {
            // uidが取得できない場合、再ログインを促す
            errorAlertRelay.accept(error.localizedDescription)
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
    
}
