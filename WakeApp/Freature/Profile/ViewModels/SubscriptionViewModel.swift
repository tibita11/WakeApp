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
    var errorAlert: Driver<String> { get }
    var collectionViewReload: Driver<Void> { get }
}

protocol SubscriptionViewModelType {
    var outputs: SubscriptionViewModelOutputs { get }
}

class SubscriptionViewModel: SubscriptionViewModelType {
    var outputs: SubscriptionViewModelOutputs { self }
    private let products = BehaviorRelay<[Product]>(value: [])
    private let errorText = PublishRelay<String>()
    private let reload = PublishRelay<Void>()
    private var observer: NSKeyValueObservation!
    private lazy var snsLinkManager: SNSLinkManager = {
       return SNSLinkManager()
    }()
    
    init() {
        observer = UserDefaults.standard.observe(\.isPurchase, options: [.initial, .new]) { [weak self] _, _ in
            self?.reload.accept(())
        }
    }
    
    // MARK: - Action
    
    func getProducts() {
        guard let productId = Bundle.main.object(forInfoDictionaryKey: "PRODUCT_ID") as? String else {
            assertionFailure("環境変数を取得できませんでした。")
            return
        }
        let productIdList = [productId]
        // AppStoreConnect商品を取得
        Task {
            do {
                let products = try await Product.products(for: productIdList)
                self.products.accept(products)
            } catch {
                self.errorText.accept(error.localizedDescription)
            }
        }
    }
    
    func purchase(row: Int) {
        let value = products.value
        let product = value[row]
        
        Task {
            do {
                let result = try await product.purchase()
                switch result {
                case .success(let verificationResult):
                    switch verificationResult {
                    case .verified(let transaction):
                        UserDefaults.standard.set(true, forKey: Const.userDefaultKeyForPurchase)
                        await transaction.finish()
                    case .unverified(_, let verificationError):
                        print("Failed purchase: \(verificationError.localizedDescription)")
                        self.errorText.accept(Const.errorText)
                    }
                case .pending:
                    break
                case .userCancelled:
                    let errorText = "購入がキャンセルされました。"
                    self.errorText.accept(errorText)
                @unknown default:
                    break
                }
            } catch {
                self.errorText.accept(error.localizedDescription)
            }
        }
    }
    
    func transitionToPrivacyPolicy() {
        snsLinkManager.transitionToPrivacyPolicy()
    }
}


// MARK: - SubscriptionViewModelOutputs

extension SubscriptionViewModel: SubscriptionViewModelOutputs {
    var collectionViewItems: Driver<[Product]> {
        self.products.asDriver(onErrorDriveWith: .empty())
    }
    
    var errorAlert: Driver<String> {
        self.errorText.asDriver(onErrorDriveWith: .empty())
    }
    
    var collectionViewReload: Driver<Void> {
        reload.asDriver(onErrorDriveWith: .empty())
    }
}


// MARK: - UserDefaults

extension UserDefaults {
    @objc dynamic var isPurchase: Bool {
        return bool(forKey: Const.userDefaultKeyForPurchase)
    }
}
