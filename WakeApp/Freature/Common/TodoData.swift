//
//  TodoData.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/07/10.
//

import Foundation

struct TodoData {
    let documentID: String
    let title: String
    let startDate: Date
    let endDate: Date
    let status: Int
    let isFocus: Bool
    
    init(documentID: String = "", title: String, startDate: Date, endDate: Date, status: Int, isFocus: Bool = false) {
        self.documentID = documentID
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.isFocus = isFocus
    }
}
