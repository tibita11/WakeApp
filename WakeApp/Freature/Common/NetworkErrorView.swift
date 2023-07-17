//
//  NetworkErrorView.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/07/17.
//

import UIKit

protocol NetworkErrorViewDelegate: AnyObject {
    /// 再試行ボタン時に実行
    func retryAction()
}

class NetworkErrorView: UIView {
    
    weak var delegate: NetworkErrorViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setUpView() {
        self.backgroundColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.5)
        self.layer.cornerRadius = 5
        
        // 注意マークの作成
        let imageSpacing = 10.0
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "exclamationmark.circle")
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: self.topAnchor, constant: imageSpacing),
            imageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: imageSpacing),
            imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -imageSpacing),
            imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: 1)
        ])
        
        // 再試行ボタン
        let buttonSpacing = 10.0
        let retryButton = UIButton()
        retryButton.addTarget(self, action: #selector(tapRetryButton), for: .touchUpInside)
        retryButton.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        retryButton.tintColor = .white
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(retryButton)
        
        NSLayoutConstraint.activate([
            retryButton.topAnchor.constraint(equalTo: self.topAnchor, constant: buttonSpacing),
            retryButton.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -buttonSpacing),
            retryButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -buttonSpacing),
            retryButton.widthAnchor.constraint(equalTo: retryButton.heightAnchor, multiplier: 1)
        ])
        
        // Labelの作成
        let labelSpacing = 10.0
        let errorLabel = UILabel()
        errorLabel.text = "インターネット接続がありません"
        errorLabel.font = UIFont.systemFont(ofSize: 14)
        errorLabel.textColor = .white
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(errorLabel)
        
        NSLayoutConstraint.activate([
            errorLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            errorLabel.leftAnchor.constraint(equalTo: imageView.rightAnchor, constant: labelSpacing),
            errorLabel.rightAnchor.constraint(equalTo: retryButton.leftAnchor, constant: -labelSpacing)
        ])
    }
    
    @objc private func tapRetryButton() {
        guard let delegate else { return }
        delegate.retryAction()
    }
}
