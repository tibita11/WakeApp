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
    var showErrorAlertDriver: Driver<String> { get }
    var transitionDriver:Driver<Void> { get }
}

protocol AccountImageSettingsViewModelType {
    var output: AccountImageSettingsViewModelOutput! { get }
    func setUp(input: AccountImageSettingsViewModelInput)
}

class AccountImageSettingsViewModel: NSObject, AccountImageSettingsViewModelType {
    var output: AccountImageSettingsViewModelOutput! { self }
    private var name: String? = nil
    private var birthday: Date?  = nil
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
    private let showErrorAlert = PublishRelay<String>()
    private let transition = PublishRelay<Void>()
    
    
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
    
    func setDefaultData(name: String, birthday: Date?) {
        self.name = name
        self.birthday = birthday
    }
    
    func setDefaultImage(status: AccountImageSettingsStatus) {
        Task {
            do {
                let defaultImageUrls = try await dataStorage.getDefaultProfileImages(names: Const.defaultProfileImages)
                switch status {
                case .create:
                    // 新規の場合は、デフォルト画像を表示
                    let iconImageUrl = try await dataStorage.getDefaultProfileImages(names: Const.iconImage)
                    selectedImageUrl = iconImageUrl.first
                case .update:
                    // 更新の場合は、登録済み画像を表示
                    let userID = try dataStorage.getCurrenUserID()
                    let imageUrl = try await dataStorage.getImageURL(uid: userID)
                    selectedImageUrl = URL(string: imageUrl)
                }
                defaultImageUrlsRelay.accept(defaultImageUrls)
                isHiddenError.accept(true)
            } catch let error as DataStorageError {
                // 復旧不可エラー
                showErrorAlert.accept(error.localizedDescription)
            } catch {
                // 再試行で復旧する可能性がある
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
            showErrorAlert.accept("\(ImageSettingsError.noImageError.localizedDescription)")
            return
        }
        
        Task {
            do {
                let userID = try dataStorage.getCurrenUserID()
                var url = selectedImageUrl
                if url == nil {
                    url = try await saveProfileImage(userID: userID, image: selectedImage!)
                }
                let userData = UserData(name: name!, birthday: birthday, imageURL: url!.absoluteString)
                try await dataStorage.saveUserData(uid: userID, data: userData)
                transition.accept(())
            } catch (let error) {
                showErrorAlert.accept("\(error.localizedDescription)")
            }
        }
    }
    
    func updateAccount() {
        if selectedImage == nil && selectedImageUrl == nil {
            showErrorAlert.accept("\(ImageSettingsError.noImageError.localizedDescription)")
            return
        }
        
        Task {
            do {
                let userID = try dataStorage.getCurrenUserID()
                var url = selectedImageUrl
                let registerdUrl = try await dataStorage.getImageURL(uid: userID)
                
                if url == nil {
                    url = try await saveProfileImage(userID: userID, image: selectedImage!)
                }
                
                let urlString = url!.absoluteString
                if urlString != registerdUrl {
                    // デフォルト以外の登録済みデータを削除
                    if !registerdUrl.contains("Image") {
                        try await dataStorage.deleteProfileImage(imageUrl: registerdUrl)
                    }
                }
                
                try await dataStorage.updateImageURL(uid: userID, url: url!.absoluteString)
            } catch let error as DataStorageError {
                // 復旧不可エラー
                showErrorAlert.accept(error.localizedDescription)
            } catch let error {
                print(error.localizedDescription)
                let errorMessage = "エラーが起きました。\nしばらくしてから再度お試しください。"
                showErrorAlert.accept(errorMessage)
            }
        }
    }
    
    private func saveProfileImage(userID: String, image: UIImage) async throws -> URL {
        guard let imageData = dataStorage.covertToData(image: image) else {
            throw ImageSettingsError.covertError
        }
        
        let url = try await dataStorage.saveProfileImage(uid: userID, imageData: imageData)
        return url
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
    
    var showErrorAlertDriver: Driver<String> {
        showErrorAlert.asDriver(onErrorDriveWith: .empty())
    }
    
    var transitionDriver: Driver<Void> {
        transition.asDriver(onErrorDriveWith: .empty())
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


// MARK: - ImageSettingsError

enum ImageSettingsError: LocalizedError {
    case noImageError
    case retryError
    case covertError
    
    var errorDescription: String? {
        switch self {
        case .noImageError:
            return "画像が選択されていません。"
        case .retryError:
            return "エラーが起きました。\nしばらくしてから再度お試しください。"
        case .covertError:
            return "画像を変更して再度お試しください。"
        }
    }
}
