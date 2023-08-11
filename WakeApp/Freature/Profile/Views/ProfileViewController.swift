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
    private let circleView = GradientView()
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
    private let errorStackView = UIStackView()
    private let errorLabel = UILabel()
    private let retryButton = UIButton()
    private var collectionView: UICollectionView!
    private var gradientLayer: CAGradientLayer!
    private let introductionStackView = UIStackView()
    private lazy var networkErrorView: NetworkErrorView = {
        let view = NetworkErrorView()
        view.delegate = self
        return view
    }()
    
    private var viewModel: ProfileViewModel!
    private let disposeBag = DisposeBag()
    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年M月d日"
        return dateFormatter
    }()
    
    
    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpLayout()
        setUpViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewModel.getInitalData()
    }
    
    
    // MARK: - Action
    
    private func setUpViewModel() {
        collectionView.register(UINib(nibName: "GoalCollectionViewCell", bundle: nil),
                                forCellWithReuseIdentifier: "GoalCollectionViewCell")
        
        viewModel = ProfileViewModel()
        
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
        
        viewModel.outputs.networkErrorHiddenDriver
            .drive(networkErrorView.rx.isHidden)
            .disposed(by: disposeBag)
        
        // CollectionViewCellの表示
        viewModel.outputs.goalDataDriver
            .do(onNext: { [weak self] items in
                self?.introductionStackView.isHidden = !items.isEmpty
            })
            .drive(collectionView.rx.items(cellIdentifier: "GoalCollectionViewCell",
                                           cellType: GoalCollectionViewCell.self)) { [weak self] row, element, cell in
                guard let self else { return }
                cell.titleLabel.text = element.title
                // 年齢表示
                var startDateText = dateFormatter.string(from: element.startDate)
                if let age = viewModel.calculateAge(at: element.startDate) {
                    startDateText += "  \(String(age))歳"
                }
                cell.startDateLabel.text = startDateText
                
                var endDateText = dateFormatter.string(from: element.endDate)
                if let age = viewModel.calculateAge(at: element.endDate) {
                    endDateText += "  \(String(age))歳"
                }
                cell.endDateLabel.text = endDateText
                
                cell.editButton.isHidden = true
                cell.additionStackView.isHidden = true
                // 達成状況
                switch element.status {
                case 0:
                    cell.statusLabel.text = "未達成"
                    cell.statusLabel.textColor = UIColor.systemGray2
                    cell.setUpNotAchievedColor()
                case 1:
                    cell.statusLabel.text = "達成🎉"
                    cell.statusLabel.textColor = UIColor.red
                    cell.setUpAchievedColor()
                default:
                    break
                }
                
                // Todoの設定
                let total = element.todos.count
                let itemHeight = 130
                let space = 10
                // 高さと幅を指定
                let width = collectionView.bounds.width - 40
                let height = CGFloat((total * itemHeight) + (2 * space))
                cell.setBaseViewWidth(to: width)
                cell.setBaseViewHeight(to: height)
                let todoContainerView = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
                
                if total != 0 {
                    for num in 0...total - 1 {
                        let todoData = element.todos[num]
                        let todoView = TodoView()
                        todoView.delegate = self
                        todoView.section = row
                        todoView.recordButton.tag = num
                        todoView.titleLabel.text = todoData.title
                        todoView.startDateLabel.text = dateFormatter.string(from: todoData.startDate)
                        todoView.endDateLabel.text = dateFormatter.string(from: todoData.endDate)
                        todoView.editButton.isHidden = true
                        if todoData.status == 0 {
                            todoView.statusLabel.text = "未達成"
                            todoView.statusLabel.textColor = .systemGray2
                        } else {
                            todoView.statusLabel.text = "達成🎉"
                            todoView.statusLabel.textColor = .red
                        }
                        todoView.frame = CGRect(x: 0,
                                                y: num * itemHeight + 10,
                                                width: Int(width),
                                                height: itemHeight)
                        todoView.focusView.alpha = todoData.isFocus ? 1 : 0
                        todoContainerView.tag = 100
                        todoContainerView.addSubview(todoView)
                    }
                }
                // 再利用を考慮するため、前回分を削除する
                if let viewToRemove = cell.baseView.viewWithTag(100) {
                    viewToRemove.removeFromSuperview()
                }
                cell.baseView.addSubview(todoContainerView)
            }
            .disposed(by: disposeBag)
        
        
    }
    
    @objc private func tapSettingsButton() {
        let vc = ProfileSettingsTableViewController()
        parent?.navigationController?.pushViewController(vc, animated: true)
    }
    
    /// UserDataの再取得
    @objc private func tapRetryButton() {
        viewModel.getInitalData()
    }
    
    
    // MARK: - Layout
    
    private func setUpLayout() {
        view.backgroundColor = .systemBackground
        
        setUpContainerView()
        setUpCircleView()
        setUpProfileContainerView()
        setUpCollectionView()
        setUpNetworkErrorView(networkErrorView)
        setUpIntroductionStackView()
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
    
    private func setUpProfileContainerView() {
        profileContainerView.translatesAutoresizingMaskIntoConstraints = false
        circleContainerView.addSubview(profileContainerView)
        
        NSLayoutConstraint.activate([
            profileContainerView.topAnchor.constraint(equalTo: circleContainerView.topAnchor, constant: heightToNavBar),
            profileContainerView.leadingAnchor.constraint(equalTo: circleContainerView.leadingAnchor, constant: 60),
            profileContainerView.trailingAnchor.constraint(equalTo: circleContainerView.trailingAnchor, constant: -60),
            profileContainerView.bottomAnchor.constraint(equalTo: circleContainerView.bottomAnchor, constant: -30)
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
        stackView.spacing = 10
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
        nameLable.textColor = .black
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
    
    private func setUpIntroductionStackView() {
        introductionStackView.translatesAutoresizingMaskIntoConstraints = false
        introductionStackView.isHidden = true
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
        imageView.image = UIImage(named: "Goal")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }
    
    private func setUpIntroductionLabel() -> UILabel {
        let label = UILabel()
        label.text = "目標達成に向けて、\n道筋を考えよう！"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }
    
    /// GoalDataを載せるCollectionView
    private func setUpCollectionView() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.estimatedItemSize = CGSize(width: 100, height: 100)
        // 上部のプロフィール箇所の高さ
        let y = circleContainerView.frame.maxY + 10
        // タブの高さ
        let tabHeight = tabBarController?.tabBar.bounds.height ?? 0
        // CollectionViewの高さ
        let height = view.bounds.height - y - tabHeight
        
        collectionView = UICollectionView(frame: CGRect(x: 20,
                                                        y: y,
                                                        width: view.bounds.width - 40,
                                                        height: height),
                                          collectionViewLayout: flowLayout)
        collectionView.delegate = self
        
        view.addSubview(collectionView)
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

extension ProfileViewController: NetworkErrorViewDelegate {
    func retryAction() {
        viewModel.getInitalData()
    }
}


// MARK: - UICollectionViewDelegate

extension ProfileViewController: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentOffsetY = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.height
        let distanceToBottom = maximumOffset - currentOffsetY

        if distanceToBottom < 500 {
            viewModel.getGoalData(isInitialDataFetch: false)
        }
    }
}


// MARK: - TodoViewDelegate

extension ProfileViewController: TodoViewDelegate {
    func transitionToNext(section: Int, row: Int) {
        let docID = viewModel.getDocumentID(section: section, row: row)
        let vc = RecordViewController(parentDocumentID: docID.parentDocumentID,
                                      documentID: docID.documentID)
        
        self.parent?.navigationController?.pushViewController(vc, animated: true)
    }
}
