//
//  SubscriptionViewController.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/08/07.
//

import UIKit
import RxSwift
import RxCocoa

class SubscriptionViewController: UIViewController {
    
    private var collectionView = UICollectionView(frame: .zero,
                                                  collectionViewLayout: UICollectionViewLayout())
    private let largeStackView = UIStackView()
    private let mediumStackView = UIStackView()
    private let restoreStackView = UIStackView()
    private let restoreLabel = UILabel()
    private let restoreButton = UIButton()
    private let restoreDescriptionLabel = UILabel()
    private let agreementStackView = UIStackView()
    private let privacyPolicyButton = UIButton()
    private let termsOfServiceButton = UIButton()
    private let lineView = UIView()
    
    private let viewModel = SubscriptionViewModel()
    private let disposeBag = DisposeBag()
    // レイアウト処理を一度のみ実行
    private lazy var initViewLayout: Void = {
       setUpLayout()
    }()
    private var heightToNavBar: CGFloat {
        var height: CGFloat = 0
        if let navigationController = self.navigationController {
            let navBarMaxY = navigationController.navigationBar.frame.maxY
            height = navBarMaxY
        }
        return height
    }
    
    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewModel.getProducts()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        _ = initViewLayout
    }
    
    // MARK: - Action
    
    private func setUpViewModel() {
        viewModel.outputs.collectionViewItems
            .drive(collectionView.rx.items(cellIdentifier: "SubscriptionCell",
                                           cellType: SubscriptionCollectionViewCell.self)) { row, element, cell in
                cell.nameLabel.text = element.displayName
                cell.priceLabel.text = element.displayPrice + "/無期限"
                cell.discriptionLabel.text = element.description
                // 購入可否
                if UserDefaults.standard.bool(forKey: Const.userDefaultKeyForPurchase) {
                    cell.purchaseButton.setTitle("購入済み", for: .normal)
                    cell.purchaseButton.backgroundColor = .systemGray2
                    cell.purchaseButton.isEnabled = false
                } else {
                    cell.purchaseButton.setTitle("購入する", for: .normal)
                    cell.purchaseButton.backgroundColor = Const.mainBlueColor
                    cell.purchaseButton.isEnabled = true
                }
                // Cellタップ時の処理を委任するため
                cell.delegate = self
                cell.purchaseButton.tag = row
            }
            .disposed(by: disposeBag)
        
        viewModel.outputs.errorAlert
            .drive(onNext: { [weak self] error in
                guard let self else { return }
                present(createErrorAlert(title: error), animated: true)
            })
            .disposed(by: disposeBag)
        
        viewModel.outputs.collectionViewReload
            .drive(onNext: { [weak self] in
                self?.collectionView.reloadData()
            })
            .disposed(by: disposeBag)
    }
    
    @objc private func tapPrivacyPolicyButton() {
        viewModel.transitionToPrivacyPolicy()
    }
    
    @objc private func tapTermsOfServiceButton() {
        viewModel.transitionToTermsOfService()
    }
    
    // MARK: - Layout
    
    private func setUpLayout() {
        self.view.backgroundColor = .systemBackground
        setUpLargeStackView()
        setUpCollectionView()
        setUpMediumStackView()
        
        setUpRestoreStackView()
        setUpRestoreLabel()
        setUpRestoreButton()
        setUpRestoreDescriptionLabel()
        
        setUpLineView()
        
        setUpAgreementStackView()
        setUpPrivacyPolicyButton()
        setUpTermsOfServiceButton()
    }
    
    private func setUpLargeStackView() {
        largeStackView.translatesAutoresizingMaskIntoConstraints = false
        largeStackView.addArrangedSubview(collectionView)
        largeStackView.addArrangedSubview(mediumStackView)
        largeStackView.axis = .vertical
        largeStackView.spacing = 5
        largeStackView.alignment = .center
        largeStackView.distribution = .fill
        self.view.addSubview(largeStackView)
        
        NSLayoutConstraint.activate([
            largeStackView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: heightToNavBar),
            largeStackView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            largeStackView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            largeStackView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -50)
        ])
    }
    
    private func setUpCollectionView() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: self.view.bounds.width - 40, height: 200)
        flowLayout.sectionInset = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        collectionView.collectionViewLayout = flowLayout
        collectionView.register(SubscriptionCollectionViewCell.self,
                                forCellWithReuseIdentifier: "SubscriptionCell")
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: largeStackView.topAnchor),
            collectionView.rightAnchor.constraint(equalTo: largeStackView.rightAnchor),
            collectionView.leftAnchor.constraint(equalTo: largeStackView.leftAnchor)
        ])
    }
    
    private func setUpMediumStackView() {
        mediumStackView.addArrangedSubview(restoreStackView)
        mediumStackView.addArrangedSubview(lineView)
        mediumStackView.addArrangedSubview(agreementStackView)
        mediumStackView.spacing = 25
        mediumStackView.axis = .vertical
        mediumStackView.alignment = .center
        mediumStackView.distribution = .fill
    }
    
    private func setUpRestoreStackView() {
        restoreStackView.addArrangedSubview(restoreLabel)
        restoreStackView.addArrangedSubview(restoreButton)
        restoreStackView.addArrangedSubview(restoreDescriptionLabel)
        restoreStackView.axis = .vertical
        restoreStackView.spacing = 5
        restoreStackView.alignment = .center
        restoreStackView.distribution = .fill
    }
    
    private func setUpRestoreLabel() {
        restoreLabel.translatesAutoresizingMaskIntoConstraints = false
        restoreLabel.text = "購入済みプランの復元"
        restoreLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        restoreLabel.tintColor = .black
        
        NSLayoutConstraint.activate([
            restoreLabel.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func setUpRestoreButton() {
        restoreButton.translatesAutoresizingMaskIntoConstraints = false
        restoreButton.setTitle("リストア", for: .normal)
        restoreButton.backgroundColor = Const.mainBlueColor
        restoreButton.layer.cornerRadius = Const.LargeBlueButtonCorner
        restoreButton.layer.masksToBounds = true
        
        NSLayoutConstraint.activate([
            restoreButton.widthAnchor.constraint(equalToConstant: 280),
            restoreButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setUpRestoreDescriptionLabel() {
        restoreDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        restoreDescriptionLabel.numberOfLines = 0
        restoreDescriptionLabel.font = UIFont.systemFont(ofSize: 12)
        restoreDescriptionLabel.tintColor = .systemGray2
        restoreDescriptionLabel.textAlignment = .center
        restoreDescriptionLabel.text = "機種変更時などで購入したプランが適用されていない場合は、リストアボタンを押してください。"
        
        NSLayoutConstraint.activate([
            restoreDescriptionLabel.widthAnchor.constraint(equalToConstant: 280),
            restoreDescriptionLabel.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setUpLineView() {
        lineView.translatesAutoresizingMaskIntoConstraints = false
        lineView.backgroundColor = .black
        
        NSLayoutConstraint.activate([
            lineView.leftAnchor.constraint(equalTo: mediumStackView.leftAnchor),
            lineView.rightAnchor.constraint(equalTo: mediumStackView.rightAnchor),
            lineView.heightAnchor.constraint(equalToConstant: 1.0)
        ])
    }
    
    private func setUpAgreementStackView() {
        agreementStackView.addArrangedSubview(privacyPolicyButton)
        agreementStackView.addArrangedSubview(termsOfServiceButton)
        agreementStackView.axis = .vertical
        agreementStackView.spacing = 10
        agreementStackView.alignment = .center
        agreementStackView.distribution = .fill
    }
    
    private func setUpPrivacyPolicyButton() {
        privacyPolicyButton.translatesAutoresizingMaskIntoConstraints = false
        privacyPolicyButton.setTitle("プライバシーポリシー", for: .normal)
        privacyPolicyButton.setTitleColor(.systemGray, for: .normal)
        privacyPolicyButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        privacyPolicyButton.addTarget(self,
                                      action: #selector(tapPrivacyPolicyButton),
                                      for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            privacyPolicyButton.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    private func setUpTermsOfServiceButton() {
        termsOfServiceButton.translatesAutoresizingMaskIntoConstraints = false
        termsOfServiceButton.setTitle("利用規約", for: .normal)
        termsOfServiceButton.setTitleColor(.systemGray, for: .normal)
        termsOfServiceButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        termsOfServiceButton.addTarget(self,
                                      action: #selector(tapTermsOfServiceButton),
                                      for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            termsOfServiceButton.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
}


// MARK: - SubscriptionCollectionViewCellDelegate

extension SubscriptionViewController: SubscriptionCollectionViewCellDelegate {
    func purchase(row: Int) {
        self.viewModel.purchase(row: row)
    }
}
