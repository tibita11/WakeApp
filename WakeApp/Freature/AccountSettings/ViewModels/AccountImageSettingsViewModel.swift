//
//  AccountImageSettingsViewModel.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/06/05.
//

import Foundation
import RxSwift
import RxCocoa
import PhotosUI
import CropViewController

struct AccountImageSettingsViewModelInput {
    let imageChangeLargeButtonObserver: Observable<Void>
    let imageChangeSmallButtonObserver: Observable<Void>
}

protocol AccountImageSettingsViewModelOutput {
    var defaultImageUrlsDriver: Driver<[URL]> { get }
    var selectedImageUrlDriver: Driver<URL> { get }
    var selectedImageDriver: Driver<UIImage> { get }
    var presentationDriver: Driver<UIViewController> { get }
    var showAlertDriver: Driver<Void> { get }
    var isHiddenErrorDriver: Driver<Bool> { get }
    var showErrorAlertDriver: Driver<Void> { get }
}

protocol AccountImageSettingsViewModelType {
    var output: AccountImageSettingsViewModelOutput! { get }
    func setUp(input: AccountImageSettingsViewModelInput)
}

class AccountImageSettingsViewModel: NSObject, AccountImageSettingsViewModelType {
    var output: AccountImageSettingsViewModelOutput! { self }
    private let dataStorage = DataStorage()
    private let disposeBag = DisposeBag()
    private var selectedImage: UIImage? = nil {
        didSet {
            guard let selectedImage else {
                return
            }
            selectedImageRelay.accept(selectedImage)
            selectedImageUrl = nil
        }
    }
    private var selectedImageUrl: URL? = nil  {
        didSet {
            guard let selectedImageUrl else {
                return
            }
            selectedImageUrlRelay.accept(selectedImageUrl)
            selectedImage = nil
        }
    }
    private let defaultImageUrlsRelay = BehaviorRelay<[URL]>(value: [])
    private let selectedImageUrlRelay = PublishRelay<URL>()
    private let selectedImageRelay = PublishRelay<UIImage>()
    private let presentation = PublishRelay<UIViewController>()
    private let showAlert = PublishRelay<Void>()
    private let isHiddenError = PublishRelay<Bool>()
    private let showErrorAlert = PublishRelay<Void>()
    
    
    // MARK: - Action
    
    func setUp(input: AccountImageSettingsViewModelInput) {
        // アルバムを表示する
        Observable.merge(input.imageChangeLargeButtonObserver, input.imageChangeSmallButtonObserver)
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                showAlert.accept(())
            })
            .disposed(by: disposeBag)
    }
    
    func setDefaultImage() {
        Task {
            do {
                let defaultImageUrls = try await dataStorage.getDefaultProfileImages(names: Const.defaultProfileImages)
                let iconImageUrl = try await dataStorage.getDefaultProfileImages(names: Const.iconImage)
                defaultImageUrlsRelay.accept(defaultImageUrls)
                selectedImageUrl = iconImageUrl.first
                isHiddenError.accept(true)
            } catch (let error) {
                print("URL取得失敗: \(error.localizedDescription)")
                isHiddenError.accept(false)
            }
        }
    }
    
    /// 画像を削除した場合に設定する画像
    func setIconImage() {
        Task {
            do {
                let iconImageUrl = try await dataStorage.getDefaultProfileImages(names: Const.iconImage)
                selectedImageUrl = iconImageUrl.first
            } catch (let error) {
                print("URL取得失敗: \(error.localizedDescription)")
            }
        }
    }
    
    func selectDefaultImage(index: Int) {
        let urls = defaultImageUrlsRelay.value
        // URLが取得できなかった場合を想定
        guard urls.count >= index + 1 else {
            return
        }
        selectedImageUrl = urls[index]
    }
    
    func showAlbum() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        presentation.accept(picker)
    }
    
    func createAccount() {
        if selectedImage == nil && selectedImageUrl == nil {
            showErrorAlert.accept(())
            return
        }
        
        if selectedImageUrl == nil {
            print("Storageへの保存を開始します。")
        } else {
            print("Firestoreへの保存を開始します。")
        }
        
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
    
    var selectedImageDriver: Driver<UIImage> {
        selectedImageRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var presentationDriver: Driver<UIViewController> {
        presentation.asDriver(onErrorDriveWith: .empty())
    }
    
    var showAlertDriver: Driver<Void> {
        showAlert.asDriver(onErrorDriveWith: .empty())
    }
    
    var isHiddenErrorDriver: Driver<Bool> {
        isHiddenError.asDriver(onErrorDriveWith: .empty())
    }
    
    var showErrorAlertDriver: Driver<Void> {
        showErrorAlert.asDriver(onErrorDriveWith: .empty())
    }
    
}


// MARK: - PHPickerViewControllerDelegate

extension AccountImageSettingsViewModel: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        let itemProvider = results.first?.itemProvider
        guard let itemProvider, itemProvider.canLoadObject(ofClass: UIImage.self) else {
            return
        }
        
        itemProvider.loadObject(ofClass: UIImage.self) { image, error in
            guard let image, let uiImage = image as? UIImage else {
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                // imageを円形にトリミングする
                let cropVC = CropViewController(croppingStyle: .circular, image: uiImage)
                cropVC.delegate = self
                self?.presentation.accept(cropVC)
            }
        }
    }
}


// MARK: - CropViewControllerDelegate

extension AccountImageSettingsViewModel: CropViewControllerDelegate {
    func cropViewController(_ cropViewController: CropViewController, didCropToCircularImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        cropViewController.dismiss(animated: true)
        // トリミング後の画像をUIに反映
        selectedImage = image
    }
}
