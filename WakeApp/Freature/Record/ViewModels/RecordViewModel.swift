//
//  RecordViewModel.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/07/16.
//

import Foundation
import RxSwift
import RxCocoa
import FirebaseFirestore

struct RecordViewModelInputs {
    let itemSelectedObserver: Observable<IndexPath>
}

protocol RecordViewModelOutputs {
    var errorAlertDriver: Driver<String> { get }
    var toDoTitleTextDriver: Driver<String> { get }
    var networkErrorHiddenDriver: Driver<Bool> { get }
    var recordsDriver: Driver<[SectionOfRecordData]> { get }
    var introductionHiddenDriver: Driver<Bool> { get }
    var transitionToEditDriver: Driver<RecordData> { get }
    var additionButtonHiddenDriver: Driver<Bool> { get }
}

protocol RecordViewModelType {
    var outputs: RecordViewModelOutputs { get }
    func setUp(inputs: RecordViewModelInputs)
}

class RecordViewModel: RecordViewModelType {
    var outputs: RecordViewModelOutputs { self }
    private let disposeBag = DisposeBag()
    private let authService = FirebaseAuthService()
    private let firestoreService = FirebaseFirestoreService()
    private let errorAlertRelay = PublishRelay<String>()
    private let toDoTitleTextRelay = PublishRelay<String>()
    private let networkErrorHiddenRelay = PublishRelay<Bool>()
    private let recordsRelay = BehaviorRelay<[SectionOfRecordData]>(value: [])
    private let transitionToEditRelay = PublishRelay<RecordData>()
    private let introductionHiddenRelay = PublishRelay<Bool>()
    private let additionButtonHiddenRelay = PublishRelay<Bool>()

    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.dateFormat = "yyyy/M/d(E)"
        return dateFormatter
    }()
    
    
    // MARK: - Action
    
    func setUp(inputs: RecordViewModelInputs) {
        inputs.itemSelectedObserver
            .subscribe(onNext: { [weak self] indexPath in
                guard let self else { return }
                let value = recordsRelay.value
                let recordData = value[indexPath.section].items[indexPath.row]
                transitionToEditRelay.accept(recordData)
            })
            .disposed(by: disposeBag)
    }
    
    private func setUpDefaultData() {
        toDoTitleTextRelay.accept("目標達成までコツコツと😊")
        recordsRelay.accept([])
        introductionHiddenRelay.accept(false)
    }
    
    func getToDoReference(parentDocumentID: String?, documentID: String?) async throws -> DocumentReference? {
        let userID = try authService.getCurrenUserID()
        if let parentDocumentID, let documentID {
            return firestoreService.createTodoReference(uid: userID,
                                                        parentDocumentID: parentDocumentID,
                                                        documentID: documentID)
        } else {
            let focusReference = firestoreService.createFocusReference(uid: userID)
            return try await firestoreService.getFocusData(reference: focusReference)
        }
    }
    
    func getInitialData(parentDocumentID: String?, documentID: String?) {
        // 開始時に非表示
        networkErrorHiddenRelay.accept(true)
        introductionHiddenRelay.accept(true)
        additionButtonHiddenRelay.accept(true)
        
        Task {
            do {
                guard let toDoReference = try await getToDoReference(parentDocumentID: parentDocumentID,
                                                                     documentID: documentID) else {
                    setUpDefaultData()
                    return
                }
                // nilでない場合は、Todoにアクセス
                async let title: String? = firestoreService.getTodoTitle(reference: toDoReference)
                async let records: [RecordData] = firestoreService.getRecordsData(toDoReference: toDoReference)
                // Todoが取得できない場合は、後の処理はしない
                guard let title = try await title else {
                    setUpDefaultData()
                    return
                }
                
                toDoTitleTextRelay.accept(title)
                let section = try await divideIntoTheSection(recordsData: records)
                recordsRelay.accept(section)
                additionButtonHiddenRelay.accept(false)
                
            } catch let error as FirebaseAuthServiceError {
                // uidが取得できない場合は、再ログインを促す
                errorAlertRelay.accept(error.localizedDescription)
            } catch let error {
                if Network.shared.isOnline() {
                    print("Error: \(error.localizedDescription)")
                    errorAlertRelay.accept(Const.errorText)
                } else {
                    // オフラインの場合、再試行ボタン表示
                    networkErrorHiddenRelay.accept(false)
                }
            }
        }
    }
    
    /// 日付毎にSectionを分ける
    ///
    /// - Parameter recordsData: RecordDataの配列
    ///
    /// - Returns: CollectionViewに表示する配列
    func divideIntoTheSection(recordsData: [RecordData]) -> [SectionOfRecordData] {
        var section: [SectionOfRecordData] = []
        var currentDate = ""
        var currentArray: [RecordData] = []
        
        for record in recordsData {
            let dateString = dateFormatter.string(from: record.date)
            
            if currentDate.isEmpty {
                currentDate = dateString
                currentArray = [record]
            } else if currentDate == dateString {
                currentArray.append(record)
            } else {
                section.append(SectionOfRecordData(header: currentDate, items: currentArray))
                currentDate = dateString
                currentArray = [record]
            }
        }
        
        if !currentDate.isEmpty {
            section.append(SectionOfRecordData(header: currentDate, items: currentArray))
        }
        
        return section
    }
    
}


// MARK: - RecordViewModelOutputs

extension RecordViewModel: RecordViewModelOutputs {
    var errorAlertDriver: Driver<String> {
        errorAlertRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var toDoTitleTextDriver: Driver<String> {
        toDoTitleTextRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var networkErrorHiddenDriver: Driver<Bool> {
        networkErrorHiddenRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var recordsDriver: Driver<[SectionOfRecordData]> {
        recordsRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var introductionHiddenDriver: Driver<Bool> {
        introductionHiddenRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var transitionToEditDriver: Driver<RecordData> {
        transitionToEditRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var additionButtonHiddenDriver: Driver<Bool> {
        additionButtonHiddenRelay.asDriver(onErrorDriveWith: .empty())
    }
}
