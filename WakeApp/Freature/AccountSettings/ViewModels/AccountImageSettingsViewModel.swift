//
//  AccountImageSettingsViewModel.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/06/05.
//

import Foundation
import RxSwift
import RxCocoa

protocol AccountImageSettingsViewModelOutput {
    var defaultImageUrlsDriver: Driver<[URL]> { get }
    var iconImageUrlDriver: Driver<[URL]> { get }
}

protocol AccountImageSettingsViewModelType {
    var output: AccountImageSettingsViewModelOutput! { get }
}

class AccountImageSettingsViewModel: AccountImageSettingsViewModelType {
    var output: AccountImageSettingsViewModelOutput! { self }
    private let defaultImageUrlsRelay = BehaviorRelay<[URL]>(value: [])
    private let iconImageUrlRelay = BehaviorRelay<[URL]>(value: [])
    
    func setUpDefaultImage() {
        Task {
            do {
                let defaultImageUrls = try await DataStorage().getDefaultProfileImages(names: Const.defaultProfileImageNames)
                defaultImageUrlsRelay.accept(defaultImageUrls)
            } catch (let error) {
                print("URL取得失敗: \(error.localizedDescription)")
            }
        }
    }
    
    func setUpIconImage() {
        Task {
            do {
                let iconImageUrl = try await DataStorage().getDefaultProfileImages(names: Const.iconImageName)
                iconImageUrlRelay.accept(iconImageUrl)
            } catch (let error) {
                print("URL取得失敗: \(error.localizedDescription)")
            }
        }
    }
    
}


// MARK: - AccountImageSettingsViewModelOutput

extension AccountImageSettingsViewModel: AccountImageSettingsViewModelOutput {
    var defaultImageUrlsDriver: Driver<[URL]> {
        defaultImageUrlsRelay.asDriver()
    }
    
    var iconImageUrlDriver: Driver<[URL]> {
        iconImageUrlRelay.asDriver()
    }
    
}
