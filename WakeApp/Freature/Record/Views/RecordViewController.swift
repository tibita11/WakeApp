//
//  RecordViewController.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/06/05.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class RecordViewController: UIViewController {
    /// 円形のViewを乗せるためのView
    private let circleContainerView = UIView()
    /// 色付きの円形View
    private let circleView = GradientView()
    private var settingsButton = UIBarButtonItem()
    private let toDoTitleView = UIView()
    private let toDoTitleLabel = UILabel()
    private var gradientLayer: CAGradientLayer!
    private let additionButton = UIButton()
    private let introductionStackView = UIStackView()
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
    
    private lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.estimatedItemSize = CGSize(width: 300, height: 100)
        flowLayout.minimumLineSpacing = 0
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 5, right: 0)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.register(UINib(nibName: "RecordDataCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "Cell")
        collectionView.register(UINib(nibName: "HeaderCollectionReusableView", bundle: nil),
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Header")
        collectionView.rx.setDelegate(self).disposed(by: disposeBag)
        return collectionView
    }()
    
    private let viewModel = RecordViewModel()
    private let disposeBag = DisposeBag()
    private var goalDocumentID: String? = nil
    private var toDoDocumentID: String? = nil
    
    private let dataSource = RxCollectionViewSectionedReloadDataSource<SectionOfRecordData> (configureCell: { dataSource, collectionView, indexPath, item in
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! RecordDataCollectionViewCell
        cell.commentLabel.text = item.comment
        cell.baseViewWidth.constant = collectionView.bounds.width
        return cell
    }, configureSupplementaryView: { dataSource, collectionView, kind, index in
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: index) as! HeaderCollectionReusableView
        header.dateLabel.text = dataSource[index.section].header
        return header
    })
    
    
    // MARK: - View Life Cycle
    
    init(parentDocumentID: String, documentID: String) {
        self.goalDocumentID = parentDocumentID
        self.toDoDocumentID = documentID
        super.init(nibName: nil, bundle: nil)
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.getInitialData(parentDocumentID: goalDocumentID,
                                 documentID: toDoDocumentID)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        _ = self.initViewLayout
    }
    
    // MARK: - Action
    
    private func setUpViewModel() {
        let inputs = RecordViewModelInputs(itemSelectedObserver: collectionView.rx.itemSelected.asObservable())
        viewModel.setUp(inputs: inputs)
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
        
        // CollectionView表示
        viewModel.outputs.recordsDriver
            .drive(collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        viewModel.outputs.introductionHiddenDriver
            .drive(introductionStackView.rx.isHidden)
            .disposed(by: disposeBag)
        
        viewModel.outputs.transitionToEditDriver
            .drive(onNext: { [weak self] recordData in
                guard let self else { return }
                let vc = RecordAdditionViewController(goalDocumentID: goalDocumentID,
                                                      toDoDocumentID: toDoDocumentID,
                                                      recordData: recordData)
                navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: disposeBag)
        
        viewModel.outputs.additionButtonHiddenDriver
            .drive(additionButton.rx.isHidden)
            .disposed(by: disposeBag)
    }
    
    @objc private func tapAdditionButton() {
        let vc = RecordAdditionViewController(goalDocumentID: goalDocumentID,
                                              toDoDocumentID: toDoDocumentID)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - Layout
    
    private func setUpLayout() {
        view.backgroundColor = .systemBackground
        
        setUpContainerView()
        setUpCircleView()
        setUpToDoTitleView()
        setUpCollectionView()
        setUpNetworkErrorView(networkErrorView)
        setUpAdditionButton()
        setUpIntroductionStackView()
    }
    
    private func setUpContainerView() {
        circleContainerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height / 3.5)
        circleContainerView.layer.masksToBounds = true
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
    
    private func setUpCollectionView() {
        let tabBarHeight = self.tabBarController?.tabBar.bounds.height ?? 0
        let rightSpacing = 30.0
        let topSpacing = 20.0
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: circleContainerView.bottomAnchor, constant: topSpacing),
            collectionView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: rightSpacing),
            collectionView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -rightSpacing),
            collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -tabBarHeight)
        ])
    }
    
    private func setUpAdditionButton() {
        let buttonSize = 60.0
        let rightSpacing = 30.0
        let bottomSpacing = 60.0
        let tabBarHeight = self.tabBarController?.tabBar.bounds.height ?? 50
        additionButton.translatesAutoresizingMaskIntoConstraints = false
        additionButton.setImage(UIImage(systemName: "pencil"), for: .normal)
        additionButton.backgroundColor = Const.mainBlueColor
        additionButton.tintColor = .white
        additionButton.layer.cornerRadius = buttonSize / 2
        additionButton.layer.masksToBounds = true
        additionButton.addTarget(self, action: #selector(tapAdditionButton), for: .touchUpInside)
        view.addSubview(additionButton)
        
        NSLayoutConstraint.activate([
            additionButton.widthAnchor.constraint(equalToConstant: buttonSize),
            additionButton.heightAnchor.constraint(equalToConstant: buttonSize),
            additionButton.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -rightSpacing),
            additionButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -(tabBarHeight + bottomSpacing))
        ])
    }
    
    private func setUpIntroductionStackView() {
        introductionStackView.translatesAutoresizingMaskIntoConstraints = false
        introductionStackView.axis = .vertical
        introductionStackView.spacing = 15
        introductionStackView.alignment = .center
        introductionStackView.distribution = .fill
        let imageView = setUpIntroductionImageView()
        let label = setUpIntroductionLabel()
        let view = setUpIntroductionView()
        introductionStackView.addArrangedSubview(imageView)
        introductionStackView.addArrangedSubview(label)
        introductionStackView.addArrangedSubview(view)
        self.view.addSubview(introductionStackView)
        
        NSLayoutConstraint.activate([
            introductionStackView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            introductionStackView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            introductionStackView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            introductionStackView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            introductionStackView.heightAnchor.constraint(equalToConstant: 250)
        ])
        
        NSLayoutConstraint.activate([
            view.leftAnchor.constraint(equalTo: introductionStackView.leftAnchor, constant: 60),
            view.rightAnchor.constraint(equalTo: introductionStackView.rightAnchor, constant: -60),
            view.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setUpIntroductionImageView() -> UIImageView {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "Book")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }
    
    private func setUpIntroductionLabel() -> UILabel {
        let label = UILabel()
        label.text = "集中項目を登録して、\n進捗やつぶやきを記録しよう！"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }
    
    private func setUpIntroductionView() -> UIView {
        let view = UIView()
        view.backgroundColor = Const.pinkColor
        view.layer.cornerRadius = 15
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.3
        view.layer.shadowRadius = 3.0
        view.layer.shadowOffset = CGSize(width: 0.0, height: 3.0)
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "※ 右上にあるボタンをタップして、\n「目標を編集をする」から設定してください。"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12)
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.topAnchor),
            label.leftAnchor.constraint(equalTo: view.leftAnchor),
            label.rightAnchor.constraint(equalTo: view.rightAnchor),
            label.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        return view
    }
    
}


// MARK: - NetworkErrorViewDelegate

extension RecordViewController: NetworkErrorViewDelegate {
    func retryAction() {
        viewModel.getInitialData(parentDocumentID: goalDocumentID,
                                 documentID: toDoDocumentID)
    }
}


// MARK: - UICollectionViewDelegate, UICollectionViewDelegateFlowLayout

extension RecordViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: self.collectionView.bounds.width, height: 30)
    }
}


// MARK: - UIViewController

extension UIViewController {
    func setUpNetworkErrorView(_ networkErrorView: NetworkErrorView) {
        let tabBarHeight = self.tabBarController?.tabBar.bounds.height ?? 50
        let bottomSpacing = 5.0
        let viewSpacing = 10.0
        let viewHeight = 50.0
        // ベースViewの作成
        networkErrorView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(networkErrorView)
        
        NSLayoutConstraint.activate([
            networkErrorView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -(tabBarHeight + bottomSpacing)),
            networkErrorView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: viewSpacing),
            networkErrorView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -viewSpacing),
            networkErrorView.heightAnchor.constraint(equalToConstant: viewHeight)
        ])
    }
}
