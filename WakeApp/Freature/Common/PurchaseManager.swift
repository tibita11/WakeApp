//
//  PurchaseManager.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/08/09.
//

import Foundation
import StoreKit

class PurchaseManager {
    func refreshPurchasedProdunts() async {
        guard let productId = Bundle.main.object(forInfoDictionaryKey: "PRODUCT_ID") as? String else {
            assertionFailure("環境変数を取得できませんでした。")
            return
        }
        
        let validSubscription = await findValidSubscription(for: productId)
        let isPurchased = validSubscription != nil
        
        UserDefaults.standard.set(isPurchased, forKey: Const.userDefaultKeyForPurchase)
    }
    
    private func findValidSubscription(for productId: String) async -> StoreKit.Transaction? {
        for await verificationResult in Transaction.currentEntitlements {
            if case .verified(let transaction) = verificationResult,
               transaction.productID == productId {
                return transaction
            }
        }
        return nil
    }
}
