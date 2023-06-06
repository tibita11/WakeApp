//
//  DataStorage.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/06/01.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage

class DataStorage {
    /// コレクション名
    private let users = "Users"
    private let image = "Image"
    
    /// uidのDocumentが存在しているかを確認する
    func checkDocument(uid: String) async throws -> Bool {
        let document = try await Firestore.firestore().collection(users).document(uid).getDocument()
        return document.exists
    }
    
    /// ImageNameからURLを取得する
    func getDefaultProfileImages(names: [String]) async throws -> [URL] {
        let imageRef = Storage.storage().reference().child(image)
        
        return try await withThrowingTaskGroup(of: URL.self, body: { group in
            for name in names {
                group.addTask {
                    try await imageRef.child(name).downloadURL()
                }
            }
            return try await group.reduce(into: [], { partialResult, url in
                partialResult.append(url)
            })
        })
    }
}
