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
            
            let listener = firestore.collection(users).document(uid).collection(goals)
                .order(by: "startDate", descending: true)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        observer.onError(error)
                        return
                    }
                    
                    let documents = snapshot?.documents ?? []
                    let goals = documents.map {
                        
                        let documentID = $0.documentID
                        
                        let title = $0["title"] as? String ?? {
                            assertionFailure("Stringにキャストできませんでした。")
                            return ""
                        }()
                        
                        let startDate = $0["startDate"] as? Timestamp ?? {
                            assertionFailure("Timestampにキャストできませんでした。")
                            return Timestamp()
                        }()
                        
                        let endDate = $0["endDate"] as? Timestamp ?? {
                            assertionFailure("Timestampにキャストできませんでした。")
                            return Timestamp()
                        }()
                        
                        let status = $0["status"] as? Int ?? {
                            assertionFailure("Intにキャストできませんでした。")
                            return 0
                        }()
                        
                        return GoalData(documentID: documentID,
                                        title: title,
                                        startDate: startDate.dateValue(),
                                        endDate: endDate.dateValue(),
                                        status: status)
                    }
                    observer.onNext(goals)
                }
            
            return Disposables.create {
                listener.remove()
            }
        }
    }
    
    /// Firestoreから指定したドキュメントIDの目標を取得
    ///
    /// - Parameters:
    ///   - uid: 取得先のコレクション名
    ///   - documentID: ドキュメントを指定
    func getGoalData(uid: String, documentID: String) -> Observable<GoalData> {
        return Observable.create { [weak self] observer in
            guard let self else {
                observer.onError(FirebaseFirestoreServiceError.noInstance)
                return Disposables.create()
            }
            
            firestore.collection(users).document(uid).collection(goals)
                .document(documentID)
                .getDocument { snapshot, error in
                    if let error {
                        observer.onError(error)
                        return
                    }
                    
                    guard let data = snapshot?.data() else {
                        // 指定したデータが無いことは想定外であるので、エラーを通知
                        observer.onError(FirebaseFirestoreServiceError.noGoalData)
                        return
                    }
                    
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
                    
                    let goalData = GoalData(documentID: documentID,
                                            title: title,
                                            startDate: startDate.dateValue(),
                                            endDate: endDate.dateValue(),
                                            status: status)
                    
                    observer.onNext(goalData)
                }
            
            return Disposables.create()
        }
    }
    

}
