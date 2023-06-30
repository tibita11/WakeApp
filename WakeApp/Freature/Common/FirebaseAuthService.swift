//
//  FirebaseAuthService.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/06/30.
//

import Foundation
import FirebaseAuth

enum FirebaseAuthServiceError: LocalizedError {
    case noUserUid
    
    var errorDescription: String? {
        switch self {
        case .noUserUid:
            return "ユーザー情報を取得できませんでした。\nアプリを再起動して再ログインをお願いします。"
        }
    }
}

class FirebaseAuthService {
    
    private let auth: Auth
    
    init() {
        auth = Auth.auth()
        auth.languageCode = "ja_JP"
    }
    
    // MARK: Action
    
    func getCurrenUserID() throws -> String {
        if let uid = auth.currentUser?.uid {
            return uid
        }
        throw FirebaseAuthServiceError.noUserUid
    }
    
    func signIn(email: String, password: String) async throws -> AuthDataResult {
        return try await auth.signIn(withEmail: email, password: password)
    }
    
    func signIn(with credential: AuthCredential) async throws -> AuthDataResult {
        return try await auth.signIn(with: credential)
    }
    
    func createUser(email: String, password: String) async throws {
        let result = try await auth.createUser(withEmail: email, password: password)
        try await result.user.sendEmailVerification()
    }
    
    func sendEmailVerification() async throws {
        try await auth.currentUser?.sendEmailVerification()
    }
    
}


// MARK: - ErrorMessage

extension FirebaseAuthService {
    func getErrorMessage(error: Error) -> String {
        let errorMessage = "エラーが起きました。\nしばらくしてから再度お試しください。"
        
        guard let error = error as NSError?,
              let errorCode = AuthErrorCode.Code(rawValue: error.code) else {
            return errorMessage
        }
        
        switch errorCode {
        case .invalidEmail:
            return "メールアドレスの形式が正しくありません。"
        case .emailAlreadyInUse:
            return "登録に使用されたメールアドレスがすでに存在しています。"
        case .weakPassword:
            return "強力なパスワードを設定してください。"
        case .userDisabled:
            return "このアカウントは使用できません。"
        case .wrongPassword:
            return "パスワードが間違っています。"
        case .userNotFound:
            return "該当アカウントが存在しません。"
        case .networkError:
            return "インターネット接続を確認してください。"
        default:
            return errorMessage
        }
    }
}

