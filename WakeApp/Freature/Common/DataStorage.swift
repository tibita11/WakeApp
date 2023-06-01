//
//  DataStorage.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/06/01.
//

import Foundation
import FirebaseAuth

class DataStorage {
    
    func createUser(email: String, password: String) async throws {
        try await Auth.auth().createUser(withEmail: email, password: password)
        try await Auth.auth().currentUser?.sendEmailVerification()
    }
    
}
