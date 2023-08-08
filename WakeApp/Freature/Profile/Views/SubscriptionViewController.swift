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
    
    // MARK: - Layout
    
    private func setUpLayout() {
        self.view.backgroundColor = .systemBackground
        setUpCollectionView()
    }
    
    private func setUpCollectionView() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: self.view.bounds.width - 40, height: 200)
        flowLayout.sectionInset = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        collectionView.collectionViewLayout = flowLayout
        collectionView.frame = CGRect(x: 0,
                                      y: heightToNavBar,
                                      width: self.view.bounds.width,
                                      height: 450)
        collectionView.register(SubscriptionCollectionViewCell.self,
                                forCellWithReuseIdentifier: "SubscriptionCell")
        self.view.addSubview(collectionView)
    }
}


// MARK: - SubscriptionCollectionViewCellDelegate

extension SubscriptionViewController: SubscriptionCollectionViewCellDelegate {
    func purchase(row: Int) {
        self.viewModel.purchase(row: row)
    }
}
