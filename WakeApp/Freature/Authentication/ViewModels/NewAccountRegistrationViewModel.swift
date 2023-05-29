//
//  NewAccountRegistrationViewModel.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/05/29.
//

import UIKit

class NewAccountRegistrationViewModel {
    
    func googleSignIn(withPresenting: UIViewController) {
        Task {
            do {
                try await GoogleAuthenticator().googleSignIn(withPresenting: withPresenting)
            } catch (let error) {
                // エラーの場合にアラート表示
                print("Googleサインイン失敗: \(error.localizedDescription)")
            }
        }
    }
}
