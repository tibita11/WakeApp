//
//  AccountImageSettingsViewController.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/06/05.
//

import UIKit
import Kingfisher
import RxSwift
import RxCocoa

class AccountImageSettingsViewController: UIViewController {
    
    @IBOutlet weak var selectedImageView: UIImageView! {
        didSet {
            selectedImageView.layer.borderColor = UIColor.systemGray2.cgColor
            selectedImageView.layer.borderWidth = 1.0
            selectedImageView.layer.cornerRadius = selectedImageView.bounds.width / 2
        }
    }
    @IBOutlet weak var selectedImageBaseView: UIView!
    @IBOutlet weak var imageChangeLargeButton: UIButton!
    @IBOutlet var defaultImageViews: [UIImageView]! {
        didSet {
            defaultImageViews.forEach {
                $0.layer.cornerRadius = $0.bounds.width / 2
            }
        }
    }
    @IBOutlet weak var createButton: UIButton! {
        didSet {
            createButton.layer.cornerRadius = Const.LargeBlueButtonCorner
        }
    }
    @IBOutlet var defaultImageButtons: [UIButton]! {
        didSet {
            var number = 0
            defaultImageButtons.forEach {
                $0.addTarget(self, action: #selector(tapDefaultImageButton), for: .touchUpInside)
                $0.tag = number
                number += 1
            }
        }
    }
    @IBOutlet weak var errorTextStackView: UIStackView!
    private let viewModel = AccountImageSettingsViewModel()
    private let disposeBag = DisposeBag()
    private let imageChangeSmallButton = UIButton()
    
    
    // MARK: - View Life Cycle
    
    init(name: String, birthday: Date?) {
        viewModel.setDefaultData(name: name, birthday: birthday)
        super.init(nibName: nil, bundle: nil)
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUp()
    }
    
    
    // MARK: - Action
    
    private func setUp() {
        setUpImageChangeButton()
        
        // ViewModel設定
        let input = AccountImageSettingsViewModelInput(imageChangeLargeButtonObserver: imageChangeLargeButton.rx.tap.asObservable(),
                                                       imageChangeSmallButtonObserver: imageChangeSmallButton.rx.tap.asObservable())
        viewModel.setUp(input: input)
        
        // デフォルト画像を表示
        viewModel.output.defaultImageUrlsDriver
            .drive(onNext: { [weak self] defaultImageUrls in
                guard let self else { return }
                for number in 0..<defaultImageUrls.count {
                    defaultImageViews[number].kf.setImage(with: defaultImageUrls[number], placeholder: UIImage(named: "placeholderImage"))
                }
            })
            .disposed(by: disposeBag)
        
        // 選択した画像を表示_URL
        viewModel.output.selectedImageUrlDriver
            .drive(onNext: { [weak self] url in
                guard let self else { return }
                selectedImageView.kf.setImage(with: url)
            })
            .disposed(by: disposeBag)
        
        // 選択した画像を表示_UIImage
        viewModel.output.selectedImageDriver
            .drive(selectedImageView.rx.image)
            .disposed(by: disposeBag)
        
        // 画像選択に関するViewController
        viewModel.output.presentationDriver
            .drive(onNext: { [weak self] viewController in
                guard let self else { return }
                present(viewController, animated: true)
            })
            .disposed(by: disposeBag)
        
        // アルバム選択アラートを表示
        viewModel.output.showAlertDriver
            .drive(onNext: { [weak self] in
                guard let self else { return }
                present(createAlert(), animated: true)
            })
            .disposed(by: disposeBag)
        
        // 通信エラーを表示
        viewModel.output.isHiddenErrorDriver
            .drive(errorTextStackView.rx.isHidden)
            .disposed(by: disposeBag)
        
        // Create時のエラーを表示
        viewModel.output.showErrorAlertDriver
            .drive(onNext: { [weak self] error in
                guard let self else { return }
                present(createErrorAlert(title: error), animated: true)
            })
            .disposed(by: disposeBag)
        
        // 画像取得
        viewModel.setDefaultImage()
    }
    
    @objc func tapDefaultImageButton(sender: UIButton) {
        viewModel.selectDefaultImage(index: sender.tag)
    }
    
    @IBAction func tapRetryButton(_ sender: Any) {
        errorTextStackView.isHidden = true
        viewModel.setDefaultImage()
    }
    
    @IBAction func tapCreateButton(_ sender: Any) {
        viewModel.createAccount()
    }
    
    /// 円形のボタンをselectedImageView上に配置する
    private func setUpImageChangeButton() {
        // 対角線の長さ
        let ImageDiagonal = selectedImageView.bounds.width * 1.41
        // 頂点から線上までの距離
        let lineLength = (ImageDiagonal - selectedImageView.bounds.width) / 2
        // 対角線の長さ
        let ButtonDiagonal = lineLength * 2
        // 高さ
        let height = ButtonDiagonal / 1.41
        imageChangeSmallButton.frame = CGRect(x: selectedImageView.bounds.width - height,
                                         y: 0,
                                         width: height,
                                         height: height)
        imageChangeSmallButton.layer.cornerRadius = imageChangeSmallButton.bounds.width / 2
        imageChangeSmallButton.setImage(UIImage(systemName: "photo.on.rectangle.angled"), for: .normal)
        imageChangeSmallButton.tintColor = .white
        imageChangeSmallButton.backgroundColor = Const.mainBlueColor
        selectedImageBaseView.addSubview(imageChangeSmallButton)
    }
    
    private func createAlert() -> UIAlertController {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let albumAction = UIAlertAction(title: "写真を選択", style: .default) { [weak self] _ in
            guard let self else { return }
            viewModel.showAlbum()
        }
        let deleteAction = UIAlertAction(title: "画像を削除", style: .destructive) { [weak self] _ in
            guard let self else { return }
            viewModel.setIconImage()
        }
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel)
        alertController.addAction(albumAction)
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        return alertController
    }
    

}
