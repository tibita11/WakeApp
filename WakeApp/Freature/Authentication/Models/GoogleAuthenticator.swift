//
//  GoogleAuthenticator.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/05/29.
//

import UIKit
import FirebaseCore
import GoogleSignIn
import FirebaseAuth

class GoogleAuthenticator {
    
    @MainActor
    func googleSignIn(withPresenting: UIViewController) async throws -> AuthCredential {
        // 初期化が正しく行われていな場合アプリを落とす
        let clientID = FirebaseApp.app()!.options.clientID!
        // Google認証
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: withPresenting)
        
        let idToken = result.user.idToken!.tokenString
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: result.user.accessToken.tokenString)
        return credential
    }
}

// MARK: -　GoogleAuthenticator

extension GoogleAuthenticator {
    func getErrorMessage(error: Error) -> String {
        let errorMessage = "エラーが起きました。\nしばらくしてから再度お試しください。"
        
        guard let error = error as? GIDSignInError else {
            return errorMessage
        }
        
        switch error.code {
        case .unknown:
            return "不明なエラーが発生しました。"
        case .canceled:
            return "認証の試行をキャンセルしました。"
        default:
            return errorMessage
        }
    }
}
