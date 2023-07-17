//
//  RecordViewController.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/06/05.
//

import UIKit
import RxSwift
import RxCocoa

class RecordViewController: UIViewController {
    /// 円形のViewを乗せるためのView
    private let circleContainerView = UIView()
    /// 色付きの円形View
    private let circleView = GradientView()
    private var settingsButton = UIBarButtonItem()
    private let toDoTitleView = UIView()
    private let toDoTitleLabel = UILabel()
    private var gradientLayer: CAGradientLayer!
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
    private lazy var networkErrorView: NetworkErrorView = {
        let view = NetworkErrorView()
        view.delegate = self
        return view
    }()
    private let viewModel = RecordViewModel()
    private let disposeBag = DisposeBag()
    
    
    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.getInitialData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        _ = self.initViewLayout
    }
    
    // MARK: - Action
    
    private func setUpViewModel() {
        // エラーアラート表示
        viewModel.outputs.errorAlertDriver
            .drive(onNext: { [weak self] error in
                guard let self else { return }
                present(createErrorAlert(title: error), animated: true)
            })
            .disposed(by: disposeBag)
        
        // ToDoTitle表示
        viewModel.outputs.toDoTitleTextDriver
            .drive(toDoTitleLabel.rx.text)
            .disposed(by: disposeBag)
        
        // 再試行ボタン表示
        viewModel.outputs.networkErrorHiddenDriver
            .drive(networkErrorView.rx.isHidden)
            .disposed(by: disposeBag)
    }
    
    @objc private func tapSettingsButton() {

    }
    
    // MARK: - Layout
    
    private func setUpLayout() {
        view.backgroundColor = .systemBackground
        
        setUpContainerView()
        setUpCircleView()
        setUpNavigationButton()
        setUpToDoTitleView()
        setUpNetworkErrorView(networkErrorView)
    }
    
    private func setUpContainerView() {
        circleContainerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height / 3.5)
        view.addSubview(circleContainerView)
    }
    
    private func setUpCircleView() {
        circleView.translatesAutoresizingMaskIntoConstraints = false
        let width = circleContainerView.bounds.width
        circleView.layer.cornerRadius = width
        circleView.layer.masksToBounds = true
        // グラデーション
        gradientLayer = CAGradientLayer()
        let gradientColors: [CGColor] = [Const.brueGradationTopColor, Const.brueGradationBottomColor]
        gradientLayer.colors = gradientColors
        gradientLayer.startPoint = CGPoint.init(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint.init(x: 1, y: 0)
        circleView.layer.insertSublayer(gradientLayer, at: 0)
        circleView.didLayoutSubView = { [weak self] bouds in
            self?.gradientLayer.frame = bouds
        }
        
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
        toDoTitleView.layer.shadowColor = UIColor.black.cgColor
        toDoTitleView.layer.shadowOpacity = 0.3
        toDoTitleView.layer.shadowRadius = 3.0
        toDoTitleView.layer.shadowOffset = CGSize(width: 0.0, height: 3.0)
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


// MARK: - NetworkErrorViewDelegate

extension RecordViewController: NetworkErrorViewDelegate {
    func retryAction() {
        viewModel.getInitialData()
    }
}


// MARK: - UIViewController

extension UIViewController {
    func setUpNetworkErrorView(_ networkErrorView: NetworkErrorView) {
        let tabBarHeight = self.tabBarController?.tabBar.bounds.height ?? 0
        let viewSpacing = 10.0
        let viewHeight = 50.0
        // ベースViewの作成
        networkErrorView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(networkErrorView)
        
        NSLayoutConstraint.activate([
            networkErrorView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -(tabBarHeight + viewSpacing*3)),
            networkErrorView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: viewSpacing),
            networkErrorView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -viewSpacing),
            networkErrorView.heightAnchor.constraint(equalToConstant: viewHeight)
        ])
    }
}
