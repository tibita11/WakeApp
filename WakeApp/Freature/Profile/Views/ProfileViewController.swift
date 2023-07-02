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
    
    /// 円形のViewを乗せるためのView
    private let circleContainerView = UIView()
    /// 色付きの円形View
    private let circleView = UIView()
    private let profileContainerView = UIView()
    private let imageView = UIImageView()
    private let stackView = UIStackView()
    private let nameLable = UILabel()
    private let futureContainerView = UIView()
    private let futureView = UIView()
    private let futureLabel = UILabel()
    private let triangleView = TriangleView()
    private var settingsButton = UIBarButtonItem()
    /// NavigationBarの高さ
    private var heightToNavBar: CGFloat {
        var height: CGFloat = 0
        if let navigationController = self.navigationController {
            let navBarMaxY = navigationController.navigationBar.frame.maxY
            height = navBarMaxY
        }
        return height
    }
    
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
        setUpProfileContainerView()
        setUpNavigationButton()
    }
    
    private func setUpContainerView() {
        circleContainerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height / 3)
        view.addSubview(circleContainerView)
    }
    
    private func setUpCircleView() {
        circleView.translatesAutoresizingMaskIntoConstraints = false
        let width = circleContainerView.bounds.width
        circleView.layer.cornerRadius = width
        circleView.backgroundColor = Const.lightBlueColor
        circleContainerView.addSubview(circleView)
        
        NSLayoutConstraint.activate([
            circleView.bottomAnchor.constraint(equalTo: circleContainerView.bottomAnchor),
            circleView.centerXAnchor.constraint(equalTo: circleContainerView.centerXAnchor),
            circleView.widthAnchor.constraint(equalToConstant: width * 2),
            circleView.heightAnchor.constraint(equalToConstant: width * 2)
        ])
    }
    
    private func setUpProfileContainerView() {
        profileContainerView.translatesAutoresizingMaskIntoConstraints = false
        circleContainerView.addSubview(profileContainerView)
        
        NSLayoutConstraint.activate([
            profileContainerView.topAnchor.constraint(equalTo: circleContainerView.topAnchor, constant: heightToNavBar),
            profileContainerView.leadingAnchor.constraint(equalTo: circleContainerView.leadingAnchor, constant: 60),
            profileContainerView.trailingAnchor.constraint(equalTo: circleContainerView.trailingAnchor, constant: -60),
            profileContainerView.bottomAnchor.constraint(equalTo: circleContainerView.bottomAnchor, constant: -40)
        ])
        // パーツ
        setUpImageView()
        setUpStackView()
    }
    
    private func setUpImageView() {
        let size: CGFloat = 50.0
        imageView.frame = CGRect(x: 0, y: 0, width: size, height: size)
        profileContainerView.addSubview(imageView)
        imageView.image = UIImage(systemName: "photo")
        imageView.layer.cornerRadius = size / 2
        imageView.tintColor = .systemGray6
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
    }
    
    private func setUpStackView() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        profileContainerView.addSubview(stackView)
        stackView.addArrangedSubview(nameLable)
        stackView.addArrangedSubview(futureContainerView)
        stackView.spacing = 20
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: profileContainerView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 15),
            stackView.trailingAnchor.constraint(equalTo: profileContainerView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: profileContainerView.bottomAnchor)
        ])
        // パーツ
        setUpNameLabel()
        setUpFutureContainerView()
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
    
    private func setUpFutureContainerView() {
        // パーツ
        setUpTriangleView()
        setUpFutureView()
    }
    
    private func setUpTriangleView() {
        triangleView.frame = CGRect(x: 0, y: 20, width: 15, height: 15)
        triangleView.backgroundColor = .clear
        futureContainerView.addSubview(triangleView)
    }
    
    private func setUpFutureView() {
        futureView.translatesAutoresizingMaskIntoConstraints = false
        futureContainerView.addSubview(futureView)
        futureView.backgroundColor = .systemBackground
        futureView.layer.cornerRadius = 15
        
        NSLayoutConstraint.activate([
            futureView.topAnchor.constraint(equalTo: futureContainerView.topAnchor),
            futureView.leadingAnchor.constraint(equalTo: triangleView.trailingAnchor),
            futureView.bottomAnchor.constraint(equalTo: futureContainerView.bottomAnchor),
            futureView.trailingAnchor.constraint(equalTo: futureContainerView.trailingAnchor)
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
            futureLabel.widthAnchor.constraint(equalTo: futureView.widthAnchor, multiplier: 1),
            futureLabel.heightAnchor.constraint(equalTo: futureView.heightAnchor, multiplier: 1)
        ])
    }
    
    private func setUpNavigationButton() {
        settingsButton = UIBarButtonItem(image: UIImage(systemName: "list.bullet"), style: .plain, target: self, action: #selector(tapSettingsButton))
        settingsButton.tintColor = .white
        parent?.navigationItem.rightBarButtonItem = settingsButton
    }
    
    
}
