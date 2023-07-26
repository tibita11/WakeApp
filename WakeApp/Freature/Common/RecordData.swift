//
//  RecordData.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/07/17.
//

import Foundation

struct RecordData {
    let documentID: String
    let date: Date
    let comment: String
    
    init(documentID: String = "", date: Date, comment: String) {
        self.documentID = documentID
        self.date = date
        self.comment = comment
    }
}
