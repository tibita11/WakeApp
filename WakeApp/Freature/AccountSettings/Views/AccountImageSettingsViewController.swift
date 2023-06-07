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
    private let viewModel = AccountImageSettingsViewModel()
    private let disposeBag = DisposeBag()
    private let imageChangeButton = UIButton()
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUp()
    }
    
    
    // MARK: - Action
    
    private func setUp() {
        setUpImageChangeButton()
        // デフォルト画像を表示
        viewModel.output.defaultImageUrlsDriver
            .drive(onNext: { [weak self] defaultImageUrls in
                guard let self else { return }
                for number in 0..<defaultImageUrls.count {
                    defaultImageViews[number].kf.setImage(with: defaultImageUrls[number])
                }
            })
            .disposed(by: disposeBag)
        // 選択した画像を表示
        viewModel.output.selectedImageUrlDriver
            .drive(onNext: { [weak self] url in
                guard let self else { return }
                selectedImageView.kf.setImage(with: url)
            })
            .disposed(by: disposeBag)
        // 画像取得
        viewModel.setDefaultImage()
        viewModel.setIconImage()
    }
    
    @objc func tapDefaultImageButton(sender: UIButton) {
        viewModel.selectDefaultImage(index: sender.tag)
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
        imageChangeButton.frame = CGRect(x: selectedImageView.bounds.width - height,
                                         y: 0,
                                         width: height,
                                         height: height)
        imageChangeButton.layer.cornerRadius = imageChangeButton.bounds.width / 2
        imageChangeButton.setImage(UIImage(systemName: "photo.on.rectangle.angled"), for: .normal)
        imageChangeButton.tintColor = .white
        imageChangeButton.backgroundColor = Const.mainBlueColor
        selectedImageBaseView.addSubview(imageChangeButton)
    }
    

}
