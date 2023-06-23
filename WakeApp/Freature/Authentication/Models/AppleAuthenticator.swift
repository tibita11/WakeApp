//
//  AppleAuthenticator.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/05/30.
//

import UIKit
import AuthenticationServices
import CryptoKit
import FirebaseAuth

class AppleAuthenticator {
    private var currentNonce: String?
    
    func getRequest() -> ASAuthorizationAppleIDRequest {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.nonce = sha256(nonce)
        
        return request
    }
    
    func appleSignIn(authorization: ASAuthorization) async throws -> AuthDataResult {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let nonce = currentNonce,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            throw AppleSignInError.signInFailed
        }
        let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)
        return try await Auth.auth().signIn(with: credential)
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError(
                "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
            )
        }
        
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        
        let nonce = randomBytes.map { byte in
            // Pick a random character from the set, wrapping around if needed.
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }

}

enum AppleSignInError: LocalizedError {
    case signInFailed
    
    var errorDescription: String? {
        switch self {
        case .signInFailed:
            return "Appleサインイン失敗"
        }
    }
}


// MARK: - ErrorMessage

extension AppleAuthenticator {
    func getErrorMessage(error: Error) -> String {
        let errorMessage = "エラーが起きました。\nしばらくしてから再度お試しください。"
        
        guard let error = error as? ASAuthorizationError else {
            return errorMessage
        }
        
        switch error.code {
        case .canceled:
            return "認証の試行をキャンセルしました。"
        case .failed:
            return "認証の試行が失敗しました。"
        case .invalidResponse:
            return "無効な応答を受け取りました。"
        case .notHandled:
            return "認証リクエストは処理されませんでした。"
        case .unknown:
            return "認証の試行が失敗しました。"
        default:
            return errorMessage
        }
    }
}
