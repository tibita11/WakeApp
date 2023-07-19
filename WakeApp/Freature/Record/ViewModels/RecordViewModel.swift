//
//  RecordViewModel.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/07/16.
//

import Foundation
import RxSwift
import RxCocoa

protocol RecordViewModelOutputs {
    var errorAlertDriver: Driver<String> { get }
    var toDoTitleTextDriver: Driver<String> { get }
    var networkErrorHiddenDriver: Driver<Bool> { get }
    var recordsDriver: Driver<[SectionOfRecordData]> { get }
}

protocol RecordViewModelType {
    var outputs: RecordViewModelOutputs { get }
}

class RecordViewModel: RecordViewModelType {
    var outputs: RecordViewModelOutputs { self }
    private let authService = FirebaseAuthService()
    private let firestoreService = FirebaseFirestoreService()
    private let errorAlertRelay = PublishRelay<String>()
    private let toDoTitleTextRelay = PublishRelay<String>()
    private let networkErrorHiddenRelay = PublishRelay<Bool>()
    private let recordsRelay = PublishRelay<[SectionOfRecordData]>()

    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.dateFormat = "yyyy/M/d(E)"
        return dateFormatter
    }()
    
    func getInitialData() {
        // 開始時に非表示
        networkErrorHiddenRelay.accept(true)
        
        do {
            let userID = try authService.getCurrenUserID()
            let focusReference = firestoreService.createFocusReference(uid: userID)
            Task {
                do {
                    // 返り値がnilの場合は、Titleを空欄で表示して、後の処理はしない
                    guard let toDoReference = try await firestoreService.getFocusData(reference: focusReference) else {
                        toDoTitleTextRelay.accept("")
                        return
                    }
                    // nilでない場合は、Todoにアクセス
                    async let title: String = firestoreService.getTodoData(reference: toDoReference)
                    async let records: [RecordData] = firestoreService.getRecordsData(toDoReference: toDoReference)
                    try await toDoTitleTextRelay.accept(title)
                    let section = try await divideIntoTheSection(recordsData: records)
                    recordsRelay.accept(section)
                    
                } catch let error {
                    if Network.shared.isOnline() {
                        print("Error: \(error.localizedDescription)")
                        // 一律したエラーアラートを表示
                        errorAlertRelay.accept(Const.errorText)
                    } else {
                        // 再試行ボタンを表示
                        networkErrorHiddenRelay.accept(false)
                    }
                }
            }
        } catch let error {
            // uidが取得できない場合、再ログインを促す
            errorAlertRelay.accept(error.localizedDescription)
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
    
}
