//
//  DataStorage.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/06/01.
//

import Foundation
import FirebaseFirestore

class DataStorage {
    /// コレクション名
    private let users = "Users"
    
    /// uidのDocumentが存在しているかを確認する
    func checkDocument(uid: String) async throws -> Bool {
        let document = try await Firestore.firestore().collection(users).document(uid).getDocument()
        return document.exists
    }
    
}
