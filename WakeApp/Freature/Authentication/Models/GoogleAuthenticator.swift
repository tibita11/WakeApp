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
    func googleSignIn(withPresenting: UIViewController) async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw GoogleSignInError.signInfailed
        }
        // Google認証
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: withPresenting)
        // Firebase認証
        guard let idToken = result.user.idToken?.tokenString else {
            throw GoogleSignInError.signInfailed
        }
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: result.user.accessToken.tokenString)
        try await Auth.auth().signIn(with: credential)
    }
    
}

enum GoogleSignInError: LocalizedError {
    case signInfailed
    
    var errorDescription: String? {
        switch self {
        case .signInfailed:
            return "Googleサインイン失敗"
        }
    }
}
