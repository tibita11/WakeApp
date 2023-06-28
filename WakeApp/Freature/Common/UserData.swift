//
//  UserData.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/06/22.
//

import Foundation

struct UserData {
    let name: String
    let birthday: Date?
    let imageURL: String
    let future: String
    
    init(name: String, birthday: Date? = nil, imageURL: String, future: String = "") {
        self.name = name
        self.birthday = birthday
        self.imageURL = imageURL
        self.future = future
    }
}
