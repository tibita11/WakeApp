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
    
    @IBOutlet weak var profileImageView: UIImageView! {
        didSet {
            profileImageView.layer.borderColor = UIColor.systemGray2.cgColor
            profileImageView.layer.borderWidth = 1.0
            profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
        }
    }
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
    private let viewModel = AccountImageSettingsViewModel()
    private let disposeBag = DisposeBag()
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUp()
    }
    
    
    // MARK: - Action
    
    private func setUp() {
        // デフォルト画像を表示
        viewModel.output.defaultImageUrlsDriver
            .drive(onNext: { [weak self] defaultImageUrls in
                guard let self else { return }
                for number in 0..<defaultImageUrls.count {
                    defaultImageViews[number].kf.setImage(with: defaultImageUrls[number])
                }
            })
            .disposed(by: disposeBag)
        // アイコン画像を表示
        viewModel.output.iconImageUrlDriver
            .drive(onNext: { [weak self] iconImageUrl in
                guard let self else { return }
                profileImageView.kf.setImage(with: iconImageUrl.first)
            })
            .disposed(by: disposeBag)
        // 画像取得
        viewModel.setUpDefaultImage()
        viewModel.setUpIconImage()
    }
    

}
