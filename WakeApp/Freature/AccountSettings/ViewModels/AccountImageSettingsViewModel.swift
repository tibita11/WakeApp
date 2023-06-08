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
    var alertDriver: Driver<UIAlertController> { get }
}

protocol AccountImageSettingsViewModelType {
    var output: AccountImageSettingsViewModelOutput! { get }
    func setUp(input: AccountImageSettingsViewModelInput)
}

class AccountImageSettingsViewModel: NSObject, AccountImageSettingsViewModelType {
    var output: AccountImageSettingsViewModelOutput! { self }
    private let dataStorage = DataStorage()
    private let disposeBag = DisposeBag()
    /// 選択中の画像を保持
    private var selectedImage: (image: UIImage?, url: URL?)! {
        didSet {
            // デフォルト画像をUIに反映
            if let url = selectedImage.url {
                selectedImageUrlRelay.accept(url)
                return
            }
            // 新規画像をUIに反映
            if let image = selectedImage.image {
                selectedImageRelay.accept(image)
            }
        }
    }
    private let defaultImageUrlsRelay = BehaviorRelay<[URL]>(value: [])
    private let selectedImageUrlRelay = PublishRelay<URL>()
    private let selectedImageRelay = PublishRelay<UIImage>()
    private let presentationRelay = PublishRelay<UIViewController>()
    private let alertRelay = PublishRelay<UIAlertController>()
    
    func setUp(input: AccountImageSettingsViewModelInput) {
        // アルバムを表示する
        Observable.merge(input.imageChangeLargeButtonObserver, input.imageChangeSmallButtonObserver)
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                alertRelay.accept(createAlert())
            })
            .disposed(by: disposeBag)
    }
    
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
                selectedImage = (nil, iconImageUrl.first)
            } catch (let error) {
                print("URL取得失敗: \(error.localizedDescription)")
            }
        }
    }
    
    /// 選択した画像はselectedImageViewに表示される
    func selectDefaultImage(index: Int) {
        let urls = defaultImageUrlsRelay.value
        let url = urls[index]
        selectedImage = (nil, url)
    }
    
    private func createAlert() -> UIAlertController {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let albumAction = UIAlertAction(title: "写真を選択", style: .default) { [weak self] _ in
            alertController.dismiss(animated: true)
            // アルバムを表示
            guard let self else { return }
            var configuration = PHPickerConfiguration()
            configuration.selectionLimit = 1
            configuration.filter = .images
            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            presentationRelay.accept(picker)
        }
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel)
        alertController.addAction(albumAction)
        alertController.addAction(cancelAction)
        return alertController
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
        presentationRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var alertDriver: Driver<UIAlertController> {
        alertRelay.asDriver(onErrorDriveWith: .empty())
    }
    
}


// MARK: - PHPickerViewControllerDelegate

extension AccountImageSettingsViewModel: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        let itemProvider = results.first?.itemProvider
        if let itemProvider = itemProvider, itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                if let image = image {
                    if let image = image as? UIImage {
                        // imageを円形にトリミングする
                        guard let self else { return }
                        DispatchQueue.main.async {
                            let cropVC = CropViewController(croppingStyle: .circular, image: image)
                            cropVC.delegate = self
                            self.presentationRelay.accept(cropVC)
                        }
                    }
                }
            }
        }
    }
}


// MARK: - CropViewControllerDelegate

extension AccountImageSettingsViewModel: CropViewControllerDelegate {
    func cropViewController(_ cropViewController: CropViewController, didCropToCircularImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        cropViewController.dismiss(animated: true)
        // トリミング後の画像をUIに反映
        selectedImage = (image, nil)
    }
}
