//
//  FirebaseFirestoreService.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/06/30.
//

import Foundation
import FirebaseFirestore
import RxSwift

enum FirebaseFirestoreServiceError: LocalizedError {
    case noUserData
    case noInstance
    case noGoalData
    
    var errorDescription: String? {
        switch self {
        case .noUserData:
            return "データが取得できませんでした。\nアプリを再起動して再ログインをお願いします。"
        case .noInstance:
            return "インスタンスの割り当てが解除されました。"
        case .noGoalData:
            return "データが取得できませんでした。"
        }
    }
}

enum LoadStatus {
    case error
    case full
    case fetching
    case loadmore
}

class FirebaseFirestoreService {
    
    private let firestore = Firestore.firestore()
    private var lastDocument: QueryDocumentSnapshot? = nil
    private var loadStatus: LoadStatus = .loadmore
    // コレクション
    private let users = "Users"
    private let goals = "Goals"
    private let todos = "Todos"
    private let focuses = "Focuses"
    private let records = "Records"
    
    
    // MARK: - Action
    
    func checkDocument(uid: String) async throws -> Bool {
        let document = try await firestore.collection(users).document(uid).getDocument()
        return document.exists
    }
    
    /// UserDataに全項目保存
    ///
    /// - Parameters:
    ///   - uid: 保存先ドキュメント名
    ///   - data: 保存するUserData
    func saveUserData(uid: String, data: UserData) {
        let birthday = data.birthday == nil ? NSNull() : Timestamp(date: data.birthday!)
        firestore.collection(users).document(uid)
            .setData(["name": data.name,
                      "birthday": birthday,
                      "imageURL": data.imageURL,
                      "future": data.future])
    }
    
    /// UserDataを取得
    ///
    /// - Parameter uid: 取得するドキュメント名
    /// - Returns: 購読するとリアルタイムで反映する
    func getUserData(uid: String) -> Observable<UserData> {
        return Observable.create { [weak self] observer in
            let listener = self!.firestore.collection(self!.users).document(uid).addSnapshotListener { snapshot, error in
                if let error {
                    observer.onError(error)
                    return
                }
                
                guard let snapshot, snapshot.exists, let data = snapshot.data() else {
                    // 取得ができなかっことを伝えるべき
                    observer.onError(FirebaseFirestoreServiceError.noUserData)
                    return
                }
                
                let timestamp = data["birthday"] as? Timestamp
                let birthday: Date? = timestamp?.dateValue()
                // キャスできない場合、ビルド時は落とす
                let name = data["name"] as? String ?? {
                    assertionFailure("Stringにキャストできませんでした。")
                    return ""
                }()
                let imageURL = data["imageURL"] as? String ?? {
                    assertionFailure("Stringにキャストできませんでした。")
                    return ""
                }()
                let future = data["future"] as? String ?? {
                    assertionFailure("Stringにキャストできませんでした。")
                    return ""
                }()
                let userData = UserData(name: name, birthday: birthday, imageURL: imageURL, future: future)
                
                observer.onNext(userData)
            }
            
            return Disposables.create {
                listener.remove()
            }
        }
    }
    
    func updateUserData(uid: String, name: String, birthday: Date?, future: String) {
        let birthday = birthday == nil ? NSNull() : Timestamp(date: birthday!)
        firestore.collection(users).document(uid)
            .updateData(["name" : name,
                         "birthday" : birthday,
                         "future" : future])
    }
    
    /// FirestoreのImageURL項目を更新
    ///
    /// - Parameters:
    ///   - uid: ドキュメント名に使用
    ///   - url: Storageの保存先URL
    func updateImageURL(uid: String, url: String) {
        firestore.collection(users).document(uid)
            .updateData(["imageURL": url]) { error in
                if let error {
                    assertionFailure("ImageURL更新失敗: \(error.localizedDescription)")
                }
            }
    }
    
    func getImageURL(uid: String) async throws -> String {
        let snapshot = try await firestore.collection(users).document(uid).getDocument()
        let data = snapshot.data()
        let imageURL = data?["imageURL"] as? String ?? {
            assertionFailure("Stringにキャストできませんでした。")
            return ""
        }()
        return imageURL
    }
    
    /// Firestoreに目標を登録
    ///
    /// - Parameters:
    ///   - uid: 保存先のドキュメント名
    ///   - goalData: 保存するデータ
    func saveGoalData(uid: String, goalData: GoalData) {
        firestore.collection(users).document(uid).collection(goals).document()
            .setData([
                "title" : goalData.title,
                "startDate" : Timestamp(date: goalData.startDate),
                "endDate" : Timestamp(date: goalData.endDate),
                "status" : goalData.status
            ])
    }
    
    /// GoalDataを更新
    ///
    /// - Parameters:
    ///   - uid: 保存先のドキュメント名
    ///   - documentID: 保存先のドキュメント名
    ///   - goalData: 保存するデータ
    func updateGoalData(uid: String, documentID: String, goalData: GoalData) {
        firestore.collection(users).document(uid).collection(goals).document(documentID)
            .setData([
                "title" : goalData.title,
                "startDate" : Timestamp(date: goalData.startDate),
                "endDate" : Timestamp(date: goalData.endDate),
                "status" : goalData.status
            ])
    }
    
    func createGoalReference(uid: String) -> CollectionReference {
        return firestore.collection(users).document(uid).collection(goals)
    }
    
    func getGoalDataDocuments(reference: CollectionReference, isInitialDataFetch: Bool) async throws -> QuerySnapshot {
        if isInitialDataFetch {
            return try await reference
                .order(by: "startDate", descending: true)
                .limit(to: 5)
                .getDocuments()
        } else {
            return try await reference
                .order(by: "startDate", descending: true)
                .limit(to: 10)
                .start(afterDocument: lastDocument!)
                .getDocuments()
        }
    }
    
    func setErrorToLoadStatus() {
        loadStatus = .error
    }
    
    func checkLoadStatus() -> Bool {
        return loadStatus != .fetching && loadStatus != .full
    }
    
    func getGoalData(uid: String, isInitialDataFetch: Bool) async throws -> [GoalData] {
        loadStatus = .fetching
        let goalReference = createGoalReference(uid: uid)
        let focusReference = createFocusReference(uid: uid)
        
        let focusSanpshot = try await focusReference.getDocument()
        let focusData = focusSanpshot.data()
        let reference = focusData?["reference"] as? DocumentReference
        let focusPath = reference?.path

        let snapshot = try await getGoalDataDocuments(reference: goalReference,
                                                      isInitialDataFetch: isInitialDataFetch)
        
        var goalDataArray: [GoalData] = []
        for document in snapshot.documents {
            let data = document.data()
            let goalsDocumentID = document.documentID
            let title = data["title"] as? String ?? {
                assertionFailure("Stringにキャストできませんでした。")
                return ""
            }()
            let startDate = data["startDate"] as? Timestamp ?? {
                assertionFailure("Timestampにキャストできませんでした。")
                return Timestamp()
            }()
            let endDate = data["endDate"] as? Timestamp ?? {
                assertionFailure("Timestampにキャストできませんでした。")
                return Timestamp()
            }()
            let status = data["status"] as? Int ?? {
                assertionFailure("Intにキャストできませんでした。")
                return 0
            }()
            let todoData = try await getTodoData(reference: document.reference.collection(todos), focusPath: focusPath)
            
            goalDataArray.append(GoalData(documentID: goalsDocumentID,
                                          title: title,
                                          startDate: startDate.dateValue(),
                                          endDate: endDate.dateValue(),
                                          status: status, todos: todoData))
        }
        
        if snapshot.count == 0 {
            lastDocument = nil
            loadStatus = .full
        } else {
            lastDocument = snapshot.documents[snapshot.count - 1]
            loadStatus = .loadmore
        }
        
        return goalDataArray
    }
    
    func getTodoData(reference: CollectionReference, focusPath: String?) async throws -> [TodoData] {
        let snapshot = try await reference.getDocuments()
        var todoDataArray: [TodoData] = []
        for document in snapshot.documents {
            let data = document.data()
            let todosDocumentID = document.documentID
            let title = data["title"] as? String ?? {
                assertionFailure("Stringにキャストできませんでした。")
                return ""
            }()
            
            let startDate = data["startDate"] as? Timestamp ?? {
                assertionFailure("Timestampにキャストできませんでした。")
                return Timestamp()
            }()
            
            let endDate = data["endDate"] as? Timestamp ?? {
                assertionFailure("Timestampにキャストできませんでした。")
                return Timestamp()
            }()
            
            let status = data["status"] as? Int ?? {
                assertionFailure("Intにキャストできませんでした。")
                return 0
            }()
            
            var isFocus: Bool = false
            if let focusPath {
                isFocus = focusPath.contains(todosDocumentID)
            }
            
            todoDataArray.append(TodoData(documentID: todosDocumentID,
                                  title: title,
                                  startDate: startDate.dateValue(),
                                  endDate: endDate.dateValue(),
                                  status: status,
                                  isFocus: isFocus))
        }
        return todoDataArray
    }
    
    /// 指定したドキュメントを削除
    ///
    /// - Parameters:
    ///   - uid: ドキュメント名
    ///   - documentID: ドキュメント名
    func deleteGoalData(uid: String, documentID: String) {
        firestore.collection(users).document(uid).collection(goals)
            .document(documentID).delete()
    }
    
    /// ドキュメントの参照先を作成
    ///
    /// - Parameters:
    ///   - uid: Usersコレクション-ドキュメント名
    ///   - parentDocumentID: 親コレクション-ドキュメント名
    ///
    ///  - Returns: 参照先
    func createTodReference(uid: String, parentDocumentID: String) -> DocumentReference {
        return firestore
            .collection(users).document(uid)
            .collection(goals).document(parentDocumentID)
            .collection(todos).document()
    }
    
    /// ドキュメントの参照先を作成
    ///
    /// - Parameters:
    ///   - uid: Usersコレクション-ドキュメント名
    ///   - parentDocumentID: 親コレクション-ドキュメント名
    ///   - documentID: 保存先ドキュメント名
    func createTodoReference(uid: String, parentDocumentID: String, documentID: String) -> DocumentReference {
        return firestore
            .collection(users).document(uid)
            .collection(goals).document(parentDocumentID)
            .collection(todos).document(documentID)
    }
    
    /// 参照先のTodoDataを取得
    ///
    /// - Parameter reference: 参照先
    func getTodoTitle(reference: DocumentReference) async throws -> String? {
        let snapshot = try await reference.getDocument()
        guard let data = snapshot.data() else {
            return nil
        }
        
        let title = data["title"] as? String ?? {
            assertionFailure("Stringにキャストできませんでした。")
            return ""
        }()
        return title
    }
    
    /// 参照先にTodoDataを保存
    ///
    /// - Parameters:
    ///   - reference: 保存先
    ///   - todoData: 保存データ
    func saveTodoData(reference: DocumentReference, todoData: TodoData) {
        reference.setData([
            "title" : todoData.title,
            "startDate" : todoData.startDate,
            "endDate" : todoData.endDate,
            "status" : todoData.status
        ])
    }
    
    /// TodoDataの更新
    ///
    /// - Parameters:
    ///   - eference: 保存先
    ///   - todoData: 更新データ
    func updateTodoData(reference: DocumentReference, todoData: TodoData) {
        reference.setData([
            "title" : todoData.title,
            "startDate" : todoData.startDate,
            "endDate" : todoData.endDate,
            "status" : todoData.status
        ])
    }
    
    /// ドキュメントの参照先を作成
    ///
    /// - Parameter uid: CurrentUserID
    func createFocusReference(uid: String) -> DocumentReference {
        return firestore.collection(focuses).document(uid)
    }
    
    /// 参照先からFocusDataを取得
    ///
    /// - Parameters:
    ///   - reference: 取得先
    ///
    /// - Returns: Todoへの参照先 nilの場合は登録なし
    func getFocusData(reference: DocumentReference) async throws -> DocumentReference? {
        let snapshot = try await reference.getDocument()
        let data = snapshot.data()
        return data?["reference"] as? DocumentReference
    }
    
    /// 参照先にFocusDataを保存
    ///
    /// - Parameters:
    ///   - reference: 保存先
    ///   - focusData: 保存するTodoデータの参照先
    func saveFocusData(reference: DocumentReference, focusData: DocumentReference) {
        reference.setData([
            "reference" : focusData
        ])
    }
    
    /// Focusesコレクションの削除
    ///
    /// - Parameter reference: 削除先
    func deleteFocusData(reference: DocumentReference) {
        reference.delete()
    }
    
    /// TodoDataの削除
    ///
    /// - Parameters:
    ///   - uid:  Usersコレクションに保存されているドキュメント名
    ///   - todoData: 削除するデータ
    func deleteTodoData(uid: String, parentDocumentID: String, todoData: TodoData) {
        firestore.collection(users).document(uid)
            .collection(goals).document(parentDocumentID)
            .collection(todos).document(todoData.documentID)
            .delete()
    }
    
    /// ドキュメントの参照先を作成
    ///
    /// - Parameters:
    ///   - toDoReference: Focusコレクションに保存されている参照先
    ///   - documentID: 保存先ドキュメント名
    ///
    ///  - Returns: 参照先
    func createRecordReference(toDoReference: DocumentReference, documentID: String) -> DocumentReference {
        // ここでtoDoreferenceがからであるとエラーが出ている
        return toDoReference.collection(records).document(documentID)
    }
    
    /// RecordDataの取得
    ///
    /// - Parameter toDoReference: 取得するRecordDataの親コレクション参照先
    ///
    /// - Returns: 取得したRecordDataの配列
    func getRecordsData(toDoReference: DocumentReference) async throws -> [RecordData] {
        let snapshot = try await toDoReference.collection(records)
            .order(by: "date", descending: true)
            .getDocuments()
        // 全て取得
        let documents = snapshot.documents
        var records: [RecordData] = []
        for document in documents {
            let documentID = document.documentID
            let data = document.data()
            let date = data["date"] as? Timestamp ?? {
                assertionFailure("Timestampにキャストできませんでした。")
                return Timestamp()
            }()
            
            let comment = data["comment"] as? String ?? {
                assertionFailure("Stringにキャストできませんでした。")
                return ""
            }()
            
            let recordData = RecordData(documentID: documentID,
                                        date: date.dateValue(),
                                        comment: comment)
            records.append(recordData)
        }
        
        return records
    }
    
    /// RecordDataの保存
    ///
    /// - Parameters:
    ///   - toDoReference: 保存するRecordDataの親コレクション参照先
    ///   - recordData: 保存データ
    func saveRecordData(toDoReference: DocumentReference, recordData: RecordData) {
        toDoReference.collection(records).document()
            .setData([
                "date" : recordData.date,
                "comment" : recordData.comment
            ])
    }
    
    /// RecordDataの更新
    ///
    /// - Parameters:
    ///   - recordReference: 保存先
    ///   - recordData: 更新データ
    func updateRecordData(recordReference: DocumentReference, recordData: RecordData) {
        recordReference.setData([
            "date" : recordData.date,
            "comment" : recordData.comment
        ])
    }
    
    /// - Parameter recordReference: 削除する参照先
    func deleteRecordData(recordReference: DocumentReference) {
        recordReference.delete()
    }
    
}
