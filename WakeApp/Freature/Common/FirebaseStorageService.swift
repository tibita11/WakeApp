//
//  DataStorage.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/06/01.
//

import UIKit
import FirebaseStorage
import RxSwift

class FirebaseStorageService {
    
    private let storage = Storage.storage()
    /// コレクション名
    private let image = "Image"
    
    // MARK: - Action
        
    func getDefaultProfileImages(names: [String]) async throws -> [URL] {
        let imageRef = storage.reference().child(image)
        
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

extension FirebaseStorageService {
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
