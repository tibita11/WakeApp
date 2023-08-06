//
//  ProfileSettingsTableViewModel.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/07/27.
//

import Foundation
import RxSwift
import RxCocoa
import StoreKit

protocol ProfileSettingsTableViewModelOutputs {
    var networkErrorAlertDriver: Driver<Void> { get }
    var errorAlertDriver: Driver<String> { get }
    var navigateToStartingViewDriver: Driver<Void> { get }
    var reloadData: Driver<Void> { get }
}

protocol ProfileSettingsTableViewModelType {
    var outputs: ProfileSettingsTableViewModelOutputs { get }
}

class ProfileSettingsTableViewModel: ProfileSettingsTableViewModelType {
    var outputs: ProfileSettingsTableViewModelOutputs { self }
    
    private let authService = FirebaseAuthService()
    private let networkErrorAlertRelay = PublishRelay<Void>()
    private let errorAlertRelay = PublishRelay<String>()
    private let navigateToStartingViewRelay = PublishRelay<Void>()
    private let reloadDataTrigger = PublishRelay<Void>()
    private var observer: NSKeyValueObservation!
    
    init() {
        observer = UserDefaults.standard.observe(\.isPurchase, options: [.initial, .new]) { [weak self] _, _ in
            self?.reloadDataTrigger.accept(())
        }
    }
    
    func unsubscribe() {
        Task {
            do {
                try await authService.unsubscribe()
                navigateToStartingViewRelay.accept(())
            } catch let error {
                if Network.shared.isOnline() {
                    // 再ログインを促す
                    print("Error: \(error.localizedDescription)")
                    errorAlertRelay.accept(Const.reLogain)
                } else {
                    networkErrorAlertRelay.accept(())
                }
            }
        }
    }
    
    func signOut() {
        do {
            try authService.signOut()
            navigateToStartingViewRelay.accept(())
        } catch let error {
            print("Error: \(error.localizedDescription)")
            errorAlertRelay.accept(Const.errorText)
        }
    }
    
    func purchase() {
        print("購入画面")
        
        guard let productId = Bundle.main.object(forInfoDictionaryKey: "PRODUCT_ID") as? String else {
            assertionFailure("環境変数を取得できませんでした。")
            return
        }
        
        let productIdList = [productId]
        
        Task {
            do {
                let products = try await Product.products(for: productIdList)
                guard let product = products.first else {
                    assertionFailure("Failed to get product")
                    return
                }
                
                let result = try await product.purchase()
                switch result {
                case .success(let verificationResult):
                    switch verificationResult {
                    case .verified(let transaction):
                        UserDefaults.standard.set(true, forKey: Const.userDefaultKeyForPurchase)
                        await transaction.finish()
                    case .unverified(_, let verificationError):
                        print("Failed purchase: \(verificationError.localizedDescription)")
                        errorAlertRelay.accept(Const.errorText)
                    }
                case .pending:
                    // 保留中は何もしない
                    break
                case .userCancelled:
                    let errorMassage = "購入がキャンセルされました。"
                    errorAlertRelay.accept(errorMassage)
                @unknown default:
                    break
                }

            } catch {
                errorAlertRelay.accept(error.localizedDescription)
            }
        }
    }
}


// MARK: - ProfileSettingsTableViewModelOutputs

extension ProfileSettingsTableViewModel: ProfileSettingsTableViewModelOutputs {
    var networkErrorAlertDriver: Driver<Void> {
        networkErrorAlertRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var errorAlertDriver: Driver<String> {
        errorAlertRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var navigateToStartingViewDriver: Driver<Void> {
        navigateToStartingViewRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var reloadData: Driver<Void> {
        reloadDataTrigger.asDriver(onErrorDriveWith: .empty())
    }
    
}


// MARK: - UserDefaults

extension UserDefaults {
    @objc dynamic var isPurchase: Bool {
        return bool(forKey: Const.userDefaultKeyForPurchase)
    }
}
