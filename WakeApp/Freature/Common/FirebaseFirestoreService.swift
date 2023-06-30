//
//  FirebaseFirestoreService.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/06/30.
//

import Foundation
import FirebaseFirestore

class FirebaseFirestoreService {
    
    private let firestore = Firestore.firestore()
    // コレクション
    private let users = "Users"

    
    // MARK: - Action
    
    func checkDocument(uid: String) async throws -> Bool {
        let document = try await firestore.collection(users).document(uid).getDocument()
        return document.exists
    }
    
    func saveUserData(uid: String, data: UserData) async throws {
        let birthday = data.birthday == nil ? NSNull() : Timestamp(date: data.birthday!)
        try await firestore.collection(users).document(uid)
            .setData(["name": data.name,
                      "birthday": birthday,
                      "imageURL": data.imageURL,
                      "future": data.future])
    }
    
    func getUserData(uid: String) async throws -> UserData {
        let snapshot = try await firestore.collection(users).document(uid).getDocument()
        
        guard snapshot.exists, let data = snapshot.data() else {
            // 登録時にデータを作成しているため、存在しないことはありえない
            // データがない場合は、再ログインを促す
            throw DataStorageError.noUserData
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
        return UserData(name: name, birthday: birthday, imageURL: imageURL, future: future)
    }
    
    func updateImageURL(uid: String, url: String) async throws {
        try await firestore.collection(users).document(uid)
            .updateData(["imageURL": url])
    }
    
    func getImageURL(uid: String) async throws -> String {
        let snapshot = try await firestore.collection(users).document(uid).getDocument()
        
        guard snapshot.exists, let data = snapshot.data() else {
            throw DataStorageError.noUserData
        }
        
        let imageURL = data["imageURL"] as? String ?? {
            assertionFailure("Stringにキャストできませんでした。")
            return ""
        }()
        return imageURL
    }

}
