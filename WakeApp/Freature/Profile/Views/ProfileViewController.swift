//
//  ProfileViewController.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/06/23.
//

import UIKit
import RxSwift
import RxCocoa
import Kingfisher

class ProfileViewController: UIViewController {
    
    private let containerView = UIView()
    private let circleView = UIView()
    private let smallStackView = UIStackView()
    private let imageView = UIImageView()
    private let nameLable = UILabel()
    private let largeStackView = UIStackView()
    private let featureContainerView = UIView()
    private let futureView = UIView()
    private let futureLabel = UILabel()
    private let triangleView = TriangleView()
    private var settingsButton = UIBarButtonItem()
    
    private let viewModel = ProfileViewModel()
    private let disposeBag = DisposeBag()
    
    
    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpLayout()
        setUpViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewModel.getUserData()
    }
    
    // MARK: - Action
    
    private func setUpViewModel() {
        viewModel.outputs.nameDriver
            .drive(nameLable.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.outputs.imageUrlDriver
            .drive(onNext: { [weak self] imageUrl in
                self?.imageView.kf.setImage(with: URL(string: imageUrl))
            })
            .disposed(by: disposeBag)
        
        viewModel.outputs.futureDriver
            .drive(futureLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.outputs.errorAlertDriver
            .drive(onNext: { [weak self] error in
                guard let self else { return }
                present(createErrorAlert(title: error), animated: true)
            })
            .disposed(by: disposeBag)
        
    }
    
    @objc private func tapSettingsButton() {
        let vc = ProfileSettingsTableViewController()
        parent?.navigationController?.pushViewController(vc, animated: true)
    }
    
    
    // MARK: - Layout
    
    private func setUpLayout() {
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
        imageView.image = UIImage(systemName: "photo")
        imageView.tintColor = .systemGray6
        imageView.contentMode = .scaleAspectFit
        
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
        futureView.translatesAutoresizingMaskIntoConstraints = false
        futureView.layer.cornerRadius = 15
        futureView.backgroundColor = .systemBackground
        featureContainerView.addSubview(futureView)
        
        NSLayoutConstraint.activate([
            futureView.topAnchor.constraint(equalTo: featureContainerView.topAnchor),
            futureView.trailingAnchor.constraint(equalTo: featureContainerView.trailingAnchor),
            futureView.bottomAnchor.constraint(equalTo: featureContainerView.bottomAnchor),
            futureView.leadingAnchor.constraint(equalTo: featureContainerView.leadingAnchor, constant: 15)
        ])
        // パーツ
        setUpFreatureLabel()
    }
    
    private func setUpFreatureLabel() {
        futureLabel.translatesAutoresizingMaskIntoConstraints = false
        futureLabel.textAlignment = .center
        futureLabel.font = UIFont.systemFont(ofSize: 16)
        futureLabel.numberOfLines = 0
        futureView.addSubview(futureLabel)
        
        NSLayoutConstraint.activate([
            futureLabel.widthAnchor.constraint(equalTo: futureView.widthAnchor),
            futureLabel.heightAnchor.constraint(equalTo: futureView.heightAnchor)
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
    
    
}
