//
//  SubscriptionCollectionViewCell.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/08/07.
//

import UIKit

protocol SubscriptionCollectionViewCellDelegate: AnyObject {
    func purchase(row: Int)
}

class SubscriptionCollectionViewCell: UICollectionViewCell {
    
    let nameLabel = UILabel()
    let priceLabel = UILabel()
    let discriptionLabel = UILabel()
    var purchaseButton: UIButton! {
        didSet {
            purchaseButton.backgroundColor = Const.mainBlueColor
            purchaseButton.setTitle("購入する", for: .normal)
            purchaseButton.tintColor = .white
            purchaseButton.layer.cornerRadius = Const.LargeBlueButtonCorner
            purchaseButton.addTarget(self, action: #selector(tapPurchaseButton), for: .touchUpInside)
        }
    }
    private let largeStackView = UIStackView()
    private let mediumStackView = UIStackView()
    weak var delegate: SubscriptionCollectionViewCellDelegate?
    
    
    // MARK: - View Life Cycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setUpLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Action
    
    @objc func tapPurchaseButton() {
        guard let delegate else {
            return
        }
        delegate.purchase(row: purchaseButton.tag)
    }
    
    
    // MARK: - Layout
    
    private func setUpLayout() {
        setUpContentView()
        setUpPurchaseButton()
        setUpLargeStackView()
        setUpDiscriptionLabel()
        setUpMediumStackView()
        setUpNameLabel()
        setUpPriceLabel()
    }
    
    private func setUpContentView() {
        self.contentView.backgroundColor = .systemBackground
        self.contentView.layer.cornerRadius = 15
        self.contentView.layer.shadowColor = UIColor.black.cgColor
        self.contentView.layer.shadowOpacity = 0.3
        self.contentView.layer.shadowRadius = 3.0
        self.contentView.layer.shadowOffset = CGSize(width: 0.0, height: 3.0)
    }
    
    private func setUpPurchaseButton() {
        purchaseButton = UIButton()
        purchaseButton.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(purchaseButton)
        
        NSLayoutConstraint.activate([
            purchaseButton.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor,
                                                   constant: -10),
            purchaseButton.widthAnchor.constraint(equalToConstant: 280),
            purchaseButton.heightAnchor.constraint(equalToConstant: 44),
            purchaseButton.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor)
        ])
    }
    
    private func setUpLargeStackView() {
        largeStackView.translatesAutoresizingMaskIntoConstraints = false
        largeStackView.addArrangedSubview(mediumStackView)
        largeStackView.addArrangedSubview(discriptionLabel)
        largeStackView.axis = .vertical
        largeStackView.spacing = 10
        largeStackView.alignment = .center
        largeStackView.distribution = .fill
        self.contentView.addSubview(largeStackView)
        
        NSLayoutConstraint.activate([
            largeStackView.topAnchor.constraint(equalTo: self.contentView.topAnchor,
                                                constant: 10),
            largeStackView.bottomAnchor.constraint(equalTo: self.purchaseButton.topAnchor,
                                                   constant: -10),
            largeStackView.widthAnchor.constraint(equalToConstant: 280),
            largeStackView.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor)
        ])
    }
    
    private func setUpDiscriptionLabel() {
        discriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        discriptionLabel.font = UIFont.systemFont(ofSize: 16)
        discriptionLabel.tintColor = .gray
        
        NSLayoutConstraint.activate([
            discriptionLabel.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func setUpMediumStackView() {
        mediumStackView.translatesAutoresizingMaskIntoConstraints = false
        mediumStackView.addArrangedSubview(nameLabel)
        mediumStackView.addArrangedSubview(priceLabel)
        mediumStackView.axis = .vertical
        mediumStackView.spacing = 5
        mediumStackView.alignment = .center
        mediumStackView.distribution = .fillEqually
    }
    
    private func setUpNameLabel() {
        nameLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
    }
    
    private func setUpPriceLabel() {
        priceLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
    }
}
