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
    
    var errorDescription: String? {
        switch self {
        case .noUserData:
            return "データが取得できませんでした。\nアプリを再起動して再ログインをお願いします。"
        }
    }
}

class FirebaseFirestoreService {
    
    private let firestore = Firestore.firestore()
    // コレクション
    private let users = "Users"

    
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

}
