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
    var selectedImageUrlDriver: Driver<URL> { get }
}

protocol AccountImageSettingsViewModelType {
    var output: AccountImageSettingsViewModelOutput! { get }
}

class AccountImageSettingsViewModel: AccountImageSettingsViewModelType {
    var output: AccountImageSettingsViewModelOutput! { self }
    private let dataStorage = DataStorage()
    private var selectedImageUrl: URL? = nil {
        didSet {
            // セットされた場合にUIに反映
            guard let selectedImageUrl else { return }
            selectedImageUrlRelay.accept(selectedImageUrl)
        }
    }
    private let defaultImageUrlsRelay = BehaviorRelay<[URL]>(value: [])
    private let selectedImageUrlRelay = PublishRelay<URL>()
    
    func setDefaultImage() {
        Task {
            do {
                let defaultImageUrls = try await dataStorage.getDefaultProfileImages(names: Const.defaultProfileImageNames)
                defaultImageUrlsRelay.accept(defaultImageUrls)
            } catch (let error) {
                print("URL取得失敗: \(error.localizedDescription)")
            }
        }
    }
    
    /// 選択画像が存在しない場合はアイコンを表示する
    func setIconImage() {
        Task {
            do {
                let iconImageUrl = try await dataStorage.getDefaultProfileImages(names: Const.iconImageName)
                selectedImageUrl = iconImageUrl.first
            } catch (let error) {
                print("URL取得失敗: \(error.localizedDescription)")
            }
        }
    }
    
    /// 選択した画像はselectedImageViewに表示される
    func selectDefaultImage(index: Int) {
        let urls = defaultImageUrlsRelay.value
        let url = urls[index]
        selectedImageUrl = url
    }
    
}


// MARK: - AccountImageSettingsViewModelOutput

extension AccountImageSettingsViewModel: AccountImageSettingsViewModelOutput {
    var defaultImageUrlsDriver: Driver<[URL]> {
        defaultImageUrlsRelay.asDriver()
    }
    
    var selectedImageUrlDriver: Driver<URL> {
        selectedImageUrlRelay.asDriver(onErrorDriveWith: .empty())
    }
    
}
