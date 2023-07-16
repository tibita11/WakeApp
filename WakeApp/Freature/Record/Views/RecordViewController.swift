//
//  RecordViewController.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/06/05.
//

import UIKit

class RecordViewController: UIViewController {
    /// 円形のViewを乗せるためのView
    private let circleContainerView = UIView()
    /// 色付きの円形View
    private let circleView = UIView()
    private var settingsButton = UIBarButtonItem()
    private let toDoTitleView = UIView()
    private let toDoTitleLabel = UILabel()
    /// NavigationBarの高さ
    private var heightToNavBar: CGFloat {
        var height: CGFloat = 0
        if let navigationController = self.navigationController {
            let navBarMaxY = navigationController.navigationBar.frame.maxY
            height = navBarMaxY
        }
        return height
    }
    // レイアウトを初回のみ実行する
    private lazy var initViewLayout : Void = {
        setUpLayout()
    }()
    
    
    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        _ = self.initViewLayout
    }
    
    // MARK: - Action
    
    @objc private func tapSettingsButton() {

    }
    
    // MARK: - Layout
    
    private func setUpLayout() {
        view.backgroundColor = .systemBackground
        
        setUpContainerView()
        setUpCircleView()
        setUpNavigationButton()
        setUpToDoTitleView()
    }
    
    private func setUpContainerView() {
        circleContainerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height / 3.5)
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
    
    private func setUpNavigationButton() {
        settingsButton = UIBarButtonItem(image: UIImage(systemName: "list.bullet"), style: .plain, target: self, action: #selector(tapSettingsButton))
        settingsButton.tintColor = .white
        parent?.navigationItem.rightBarButtonItem = settingsButton
    }
    
    private func setUpToDoTitleView() {
        toDoTitleView.translatesAutoresizingMaskIntoConstraints = false
        toDoTitleView.backgroundColor = .systemBackground
        toDoTitleView.layer.cornerRadius = 5
        circleContainerView.addSubview(toDoTitleView)
        
        NSLayoutConstraint.activate([
            toDoTitleView.topAnchor.constraint(equalTo: circleContainerView.topAnchor, constant: heightToNavBar),
            toDoTitleView.leftAnchor.constraint(equalTo: circleContainerView.leftAnchor, constant: 50),
            toDoTitleView.rightAnchor.constraint(equalTo: circleContainerView.rightAnchor, constant: -50),
            toDoTitleView.bottomAnchor.constraint(equalTo: circleContainerView.bottomAnchor, constant: -50)
        ])
        
        // パーツ
        setUpToDoTitleLabel()
    }
    
    private func setUpToDoTitleLabel() {
        toDoTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        toDoTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        toDoTitleLabel.numberOfLines = 0
        toDoTitleLabel.textAlignment = .center
        toDoTitleView.addSubview(toDoTitleLabel)
        
        NSLayoutConstraint.activate([
            toDoTitleLabel.widthAnchor.constraint(equalTo: toDoTitleView.widthAnchor, multiplier: 1, constant: -20),
            toDoTitleLabel.centerXAnchor.constraint(equalTo: toDoTitleView.centerXAnchor),
            toDoTitleLabel.topAnchor.constraint(equalTo: toDoTitleView.topAnchor),
            toDoTitleLabel.bottomAnchor.constraint(equalTo: toDoTitleView.bottomAnchor)
        ])
    }
    
}
