//
//  ProfileViewController.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/06/23.
//

import UIKit

class ProfileViewController: UIViewController {
    
    private let containerView = UIView()
    private let circleView = UIView()
    private let smallStackView = UIStackView()
    private let imageView = UIImageView()
    private let nameLable = UILabel()
    private let largeStackView = UIStackView()
    private let featureContainerView = UIView()
    private let featureView = UIView()
    private let featureLabel = UILabel()
    private let triangleView = TriangleView()
    private var settingsButton = UIBarButtonItem()
    
    
    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUp()
    }
    
    
    //MARK: - Action
    
    private func setUp() {
        view.backgroundColor = .systemBackground
        
        setUpContainerView()
        setUpCircleView()
        setUpLargeStackView()
        setUpNavigationButton()
    }
    
    private func setUpContainerView() {
        containerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height / 3)
        view.addSubview(containerView)
    }
    
    private func setUpCircleView() {
        circleView.translatesAutoresizingMaskIntoConstraints = false
        let width = containerView.bounds.width
        circleView.layer.cornerRadius = width
        circleView.backgroundColor = Const.lightBlueColor
        containerView.addSubview(circleView)
        
        NSLayoutConstraint.activate([
            circleView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            circleView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            circleView.widthAnchor.constraint(equalToConstant: width * 2),
            circleView.heightAnchor.constraint(equalToConstant: width * 2)
        ])
    }
    
    private func setUpLargeStackView() {
        largeStackView.translatesAutoresizingMaskIntoConstraints = false
        largeStackView.addArrangedSubview(imageView)
        largeStackView.addArrangedSubview(smallStackView)
        containerView.addSubview(largeStackView)
        largeStackView.spacing = 15
        largeStackView.axis = .horizontal
        largeStackView.alignment = .top
        largeStackView.distribution = .fill
        
        NSLayoutConstraint.activate([
            largeStackView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            largeStackView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
        // パーツ
        setUpImageView()
        setUpSmallStackView()
    }
    
    private func setUpImageView() {
        let size: CGFloat = 50.0
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = size / 2
        imageView.layer.masksToBounds = true
        // ここはDBから取得知ったものを表示
        imageView.image = UIImage(named: "WAKE")
        
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: size),
            imageView.heightAnchor.constraint(equalToConstant: size)
        ])
    }
    
    private func setUpSmallStackView() {
        smallStackView.translatesAutoresizingMaskIntoConstraints = false
        smallStackView.addArrangedSubview(nameLable)
        smallStackView.addArrangedSubview(featureContainerView)
        smallStackView.spacing = 20
        smallStackView.axis = .vertical
        smallStackView.alignment = .fill
        smallStackView.distribution = .fill
        // パーツ
        setUpNameLabel()
        setUpFeatureContainerView()
    }
    
    private func setUpNameLabel() {
        nameLable.translatesAutoresizingMaskIntoConstraints = false
        // ここはDBから取得知ったものを表示
        nameLable.text = ""
        nameLable.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        nameLable.textColor = .white
        nameLable.textAlignment = .left
        
        NSLayoutConstraint.activate([
            nameLable.heightAnchor.constraint(equalToConstant: 25)
        ])
    }
    
    private func setUpFeatureContainerView() {
        featureContainerView.translatesAutoresizingMaskIntoConstraints = false
        featureContainerView.backgroundColor = .clear
        
        NSLayoutConstraint.activate([
            featureContainerView.heightAnchor.constraint(equalToConstant: 100),
            featureContainerView.widthAnchor.constraint(equalToConstant: 200)
        ])
        // パーツ
        setUpFeatureView()
        setUpTriangleView()
    }
    
    private func setUpFeatureView() {
        featureView.translatesAutoresizingMaskIntoConstraints = false
        featureView.layer.cornerRadius = 15
        featureView.backgroundColor = .systemBackground
        featureContainerView.addSubview(featureView)
        
        NSLayoutConstraint.activate([
            featureView.topAnchor.constraint(equalTo: featureContainerView.topAnchor),
            featureView.trailingAnchor.constraint(equalTo: featureContainerView.trailingAnchor),
            featureView.bottomAnchor.constraint(equalTo: featureContainerView.bottomAnchor),
            featureView.leadingAnchor.constraint(equalTo: featureContainerView.leadingAnchor, constant: 15)
        ])
        // パーツ
        setUpFreatureLabel()
    }
    
    private func setUpFreatureLabel() {
        featureLabel.translatesAutoresizingMaskIntoConstraints = false
        // ここはDBから取得知ったものを表示
        featureLabel.text = ""
        featureLabel.textAlignment = .center
        featureLabel.font = UIFont.systemFont(ofSize: 16)
        featureLabel.numberOfLines = 0
        featureView.addSubview(featureLabel)
        
        NSLayoutConstraint.activate([
            featureLabel.widthAnchor.constraint(equalTo: featureView.widthAnchor),
            featureLabel.heightAnchor.constraint(equalTo: featureView.heightAnchor)
        ])
    }
    
    private func setUpTriangleView() {
        triangleView.translatesAutoresizingMaskIntoConstraints = false
        triangleView.backgroundColor = .clear
        featureContainerView.addSubview(triangleView)
        
        NSLayoutConstraint.activate([
            triangleView.topAnchor.constraint(equalTo: featureContainerView.topAnchor, constant: 20),
            triangleView.leadingAnchor.constraint(equalTo: featureContainerView.leadingAnchor),
            triangleView.widthAnchor.constraint(equalToConstant: 15),
            triangleView.heightAnchor.constraint(equalToConstant: 15)
        ])
    }
    
    private func setUpNavigationButton() {
        settingsButton = UIBarButtonItem(image: UIImage(systemName: "list.bullet"), style: .plain, target: self, action: #selector(tapSettingsButton))
        settingsButton.tintColor = .white
        parent?.navigationItem.rightBarButtonItem = settingsButton
    }
    
    @objc private func tapSettingsButton() {

    }
    
    
}
