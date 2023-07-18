//
//  SectionOfRecordData.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/07/18.
//

import RxDataSources

struct SectionOfRecordData {
    var header: String
    var items: [Item]
}

extension SectionOfRecordData: SectionModelType {
    typealias Item = RecordData
    
    init(original: SectionOfRecordData, items: [RecordData]) {
        self = original
        self.items = items
    }
}
