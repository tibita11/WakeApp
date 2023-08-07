//
//  TransactionObserver.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/08/07.
//

import Foundation
import StoreKit

final class TransactionObserver {
    var updates: Task<Void, Never>? = nil
    
    init() {
        updates = newTransactionListenerTask()
    }
    
    deinit {
        updates?.cancel()
    }
    
    private func newTransactionListenerTask() -> Task<Void, Never> {
        Task(priority: .background) {
            for await verificationResult in Transaction.updates {
                await self.handle(updatedTransaction: verificationResult)
            }
        }
    }
    
    private func handle(updatedTransaction verificationResult: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = verificationResult else {
            // 未検証は無視する
            return
        }
        
        if transaction.revocationDate != nil {
            // 返金の場合UserDefaultをfalseに変更
            UserDefaults.standard.set(false, forKey: Const.userDefaultKeyForPurchase)
        } else {
            UserDefaults.standard.set(true, forKey: Const.userDefaultKeyForPurchase)
        }
        
        await transaction.finish()
    }
}
