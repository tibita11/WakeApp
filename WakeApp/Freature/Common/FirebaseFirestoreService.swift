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

class FirebaseFirestoreService {
    
    private let firestore = Firestore.firestore()
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
        
        guard snapshot.exists, let data = snapshot.data() else {
            throw FirebaseFirestoreServiceError.noUserData
        }
        
        let imageURL = data["imageURL"] as? String ?? {
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
    
    /// Firestoreから目標を取得
    ///
    /// - Parameter uid: 取得先のコレクション名
    func getGoalData(uid: String) -> Observable<[GoalData]> {
        return Observable.create { [weak self] observer in
            guard let self else {
                observer.onError(FirebaseFirestoreServiceError.noInstance)
                return Disposables.create()
            }
            
            // Focusに入っている参照先を取得する
            firestore.collection(focuses).document(uid).getDocument { [weak self] snapshot, error in
                guard let self else {
                    observer.onError(FirebaseFirestoreServiceError.noInstance)
                    return
                }
                
                if let error {
                    observer.onError(error)
                    return
                }
                
                let data = snapshot?.data()
                // todoDocumentIDとの比較用
                let focusReference = data?["reference"] as? DocumentReference
                
                firestore.collection(users).document(uid).collection(goals)
                    .order(by: "startDate", descending: true)
                    .getDocuments { snapshot, error in
                        if let error {
                            observer.onError(error)
                            return
                        }
                        
                        let documents = snapshot?.documents ?? []
                        var goals: [GoalData] = []
                        // この処理が全て終わるのを待つ
                        let mainGroup = DispatchGroup()
                        let dispatchQueue = DispatchQueue(label: "queue")
                        
                        for document in documents {
                            let dispatchSemaphore = DispatchSemaphore(value: 0)
                            
                            dispatchQueue.async(group: mainGroup) {
                                mainGroup.enter()
                                
                                let goalsDocumentID = document.documentID
                                let data = document.data()
                                
                                
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
                                
                                // Todosコレクションを同時に取得
                                var todos: [TodoData] = []
                                document.reference.collection("Todos")
                                    .order(by: "startDate", descending: true).getDocuments { snapshot, error in
                                        if let error {
                                            observer.onError(error)
                                            mainGroup.leave()
                                            dispatchSemaphore.signal()
                                            return
                                        }
                                        
                                        let documents = snapshot?.documents ?? []
                                        for document in documents {
                                            let todosDocumentID = document.documentID
                                            let data = document.data()
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
                                            if let path = focusReference?.path {
                                                isFocus = path.contains(todosDocumentID)
                                            }
                                            
                                            todos.append(TodoData(parentDocumentID: goalsDocumentID,
                                                                  documentID: todosDocumentID,
                                                                  title: title,
                                                                  startDate: startDate.dateValue(),
                                                                  endDate: endDate.dateValue(),
                                                                  status: status,
                                                                  isFocus: isFocus))
                                        }
                                        
                                        goals.append(GoalData(documentID: goalsDocumentID,
                                                              title: title,
                                                              startDate: startDate.dateValue(),
                                                              endDate: endDate.dateValue(),
                                                              status: status, todos: todos))
                                        
                                        mainGroup.leave()
                                        dispatchSemaphore.signal()
                                    }
                                dispatchSemaphore.wait()
                            }
                        }
                        
                        mainGroup.notify(queue: .main) {
                            observer.onNext(goals)
                            observer.onCompleted()
                        }
                    }
            }
            
            return Disposables.create()
        }
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
    func getTodoData(reference: DocumentReference) async throws -> String? {
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
    func deleteTodoData(uid: String, todoData: TodoData) {
        firestore.collection(users).document(uid)
            .collection(goals).document(todoData.parentDocumentID)
            .collection(todos).document(todoData.documentID)
            .delete()
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
            let data = document.data()
            
            let date = data["date"] as? Timestamp ?? {
                assertionFailure("Timestampにキャストできませんでした。")
                return Timestamp()
            }()
            
            let comment = data["comment"] as? String ?? {
                assertionFailure("Stringにキャストできませんでした。")
                return ""
            }()
            
            let recordData = RecordData(date: date.dateValue(), comment: comment)
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
    
}
