//
//  DataStorage.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/06/01.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import RxSwift

// MARK: - DataStorageError

enum DataStorageError: LocalizedError {
    case noUserData
    
    var errorDescription: String? {
        switch self {
        case .noUserData:
            return "データが取得できませんでした。\nアプリを再起動して再ログインをお願いします。"
        }
    }
}

class DataStorage {
    private let firestore = Firestore.firestore()
    private let storage = Storage.storage()
    /// コレクション名
    private let users = "Users"
    private let image = "Image"
    
    // MARK: - Firestore
    
    func checkDocument(uid: String) async throws -> Bool {
        let document = try await firestore.collection(users).document(uid).getDocument()
        return document.exists
    }
    
    func saveUserData(uid: String, data: UserData) async throws {
        let birthday = data.birthday == nil ? NSNull() : Timestamp(date: data.birthday!)
        try await firestore.collection(users).document(uid).setData(["name": data.name,
                                                                     "birthday": birthday,
                                                                     "imageURL": data.imageURL,
                                                                     "future": data.future])
    }
    
    func updateImageURL(uid: String, url: String) async throws {
        try await firestore.collection(users).document(uid).updateData(["imageURL": url])
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
    
    
    // MARK: - Storage
    
    /// デフォルト画像格納場所への参照
    func getDefaultImageFileRef() -> StorageReference {
        return Storage.storage().reference().child(image)
    }
    
    func getDefaultProfileImages(names: [String]) async throws -> [URL] {
        let imageRef = getDefaultImageFileRef()
        
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
    
    func saveProfileImage(uid: String, imageData: Data) async throws -> URL {
        let imageRef = storage.reference().child(uid).child("\(UUID().uuidString).jpg")
        _ = try await imageRef.putDataAsync(imageData)
        let url = try await imageRef.downloadURL()
        return url
    }
    
    func deleteProfileImage(imageUrl: String) async throws {
        let imageRef = storage.reference(forURL: imageUrl)
        try await imageRef.delete()
    }
    
}


// MARK: - Imageリサイズ用に拡張

extension UIImage {
    
    /// - Parameter percentage:圧縮率
    func resizeImage(withPercentage percentage: CGFloat) -> UIImage? {
        // 圧縮後のサイズ情報
        let canvas = CGSize(width: size.width * percentage, height: size.height * percentage)
        // 圧縮画像を返す
        return UIGraphicsImageRenderer(size: canvas, format: imageRendererFormat).image {
            _ in draw(in: CGRect(origin: .zero, size: canvas))
        }
    }
}


// MARK: - Imageリサイズ用に拡張

extension DataStorage {
    /// Storageに保存する際のDataを作成する
    /// - Returns: jpegDataに変換不可はnilが返る
    func covertToData(image: UIImage) -> Data? {
        let minSizeInKB: Double = 100.0
        let maxSizeInKB: Double = 1000.0
        let data = image.jpegData(compressionQuality: 1)
        let size = Double(data?.count ?? 0 / 1024)
        // そのまま返す
        guard size > minSizeInKB else {
            return data
        }
        // jpegDataに変換
        guard size > maxSizeInKB else {
            return resizeData(image: image)
        }
        // 画像をリサイズ後にjpegDataに変換
        let resizedImage = image.resizeImage(withPercentage: 0.5)!
        return resizeData(image: resizedImage)
    }
    
    /// 100KB以下になるまで圧縮を繰り返す
    /// - Returns: jpegDataに変換不可はnilが返る
    private func resizeData(image: UIImage) -> Data? {
        let sizeInKB:Double = 100.0
        var complessionQuality = CGFloat(1)
        var data = image.jpegData(compressionQuality: complessionQuality)
        while (Double(data?.count ?? 0) / 1024) > sizeInKB && complessionQuality > 0 {
            complessionQuality -= 0.1
            data = image.jpegData(compressionQuality: complessionQuality)
        }
        return data
    }
}
