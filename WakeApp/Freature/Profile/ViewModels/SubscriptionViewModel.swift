//
//  SubscriptionViewModel.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/08/08.
//

import Foundation
import RxSwift
import RxCocoa
import StoreKit

protocol SubscriptionViewModelOutputs {
    var collectionViewItems: Driver<[Product]> { get }
}

protocol SubscriptionViewModelType {
    var outputs: SubscriptionViewModelOutputs { get }
}

class SubscriptionViewModel: SubscriptionViewModelType {
    var outputs: SubscriptionViewModelOutputs { self }
    private let prducts = PublishRelay<[Product]>()
    
    // MARK: - Action
    
    func getProducts() {
        guard let productId = Bundle.main.object(forInfoDictionaryKey: "PRODUCT_ID") as? String else {
            assertionFailure("環境変数を取得できませんでした。")
            return
        }
        let productIdList = [productId]
        // AppStoreConnect商品を取得
        Task {
            let products = try await Product.products(for: productIdList)
            self.prducts.accept(products)
        }
    }
}


// MARK: - SubscriptionViewModelOutputs

extension SubscriptionViewModel: SubscriptionViewModelOutputs {
    var collectionViewItems: Driver<[Product]> {
        self.prducts.asDriver(onErrorDriveWith: .empty())
    }
}
