//
//  GoalsEditingViewController.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/07/03.
//

import UIKit
import RxSwift
import RxCocoa

class GoalsEditingViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewFlowLayout: UICollectionViewFlowLayout! {
        didSet {
            collectionViewFlowLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        }
    }
    @IBOutlet weak var networkErrorView: UIView! {
        didSet {
            let view = NetworkErrorView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.delegate = self
            networkErrorView.addSubview(view)
            
            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: networkErrorView.topAnchor),
                view.leftAnchor.constraint(equalTo: networkErrorView.leftAnchor),
                view.rightAnchor.constraint(equalTo: networkErrorView.rightAnchor),
                view.bottomAnchor.constraint(equalTo: networkErrorView.bottomAnchor)
            ])
        }
    }
    
    private var viewModel: GoalsEditingViewModel!
    private let disposeBag = DisposeBag()
    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年M月d日"
        return dateFormatter
    }()
    
    private let introductionStackView = UIStackView()
    private lazy var initViewLayout: Void = {
        setUpLayout()
    }()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUp()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 初期データの取得
        viewModel.getInitialData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        _ = initViewLayout
    }
    
    
    // MARK: - Action
    
    private func setUp() {
        // 別の方法でセルの大きさを変えてみる
        collectionView.register(UINib(nibName: "GoalCollectionViewCell", bundle: nil),
                                forCellWithReuseIdentifier: "GoalCollectionViewCell")
        collectionView.delegate = self
        
        viewModel = GoalsEditingViewModel()
        
        // itemをcollectionViewに表示
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
                // タップされた場合に該当ドキュメントの編集画面に移るため保持
                cell.editButton.tag = row
                // Todo登録時にドキュメントIDが必要なため保持
                cell.additionButton.tag = row
                cell.delegate = self
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
                        todoView.section = row
                        todoView.editButton.tag = num
                        todoView.delegate = self
                        todoView.titleLabel.text = todoData.title
                        todoView.startDateLabel.text = dateFormatter.string(from: todoData.startDate)
                        todoView.endDateLabel.text = dateFormatter.string(from: todoData.endDate)
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
                        todoView.focusView.isHidden = !todoData.isFocus
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
        
        viewModel.outputs.networkErrorHiddenDriver
            .drive(networkErrorView.rx.isHidden)
            .disposed(by: disposeBag)
        
        // エラーアラート表示
        viewModel.outputs.errorAlertDriver
            .drive(onNext: { [weak self] error in
                guard let self else { return }
                present(createErrorAlert(title: error), animated: true)
            })
            .disposed(by: disposeBag)
        
        // ドキュメント名を初期値とした登録画面への遷移
        viewModel.outputs.transitionToGoalRegistrationDriver
            .drive(onNext: { [weak self] goalData in
                guard let self else { return }
                let vc = GoalRegistrationViewController(goalData: goalData)
                navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: disposeBag)
        
        // Todo登録画面に初期値を代入して遷移
        viewModel.outputs.transitionToTodoRegistrationDriver
            .drive(onNext: { [weak self] (parentDocumentID, todoData) in
                guard let self else { return }
                let vc = TodoRegistrationViewController(parentDocumentID: parentDocumentID,
                                                        todoData: todoData)
                navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: disposeBag)
        
        
    }
    
    /// 目標追加画面に遷移
    @IBAction func tapAdditionButton(_ sender: Any) {
        let vc = GoalRegistrationViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    /// GoalDataを再取得
    @objc private func tapRetryButton() {
        viewModel.getInitialData()
    }
    
    
    // MARK: - Layout
    
    private func setUpLayout() {
        setUpIntroductionStackView()
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
        introductionStackView.addArrangedSubview(imageView)
        introductionStackView.addArrangedSubview(label)
        self.view.addSubview(introductionStackView)
        
        NSLayoutConstraint.activate([
            introductionStackView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            introductionStackView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            introductionStackView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            introductionStackView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            introductionStackView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    private func setUpIntroductionImageView() -> UIImageView {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "Navi")
        imageView.bounds.size = CGSize(width: 100, height: 100)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }
    
    private func setUpIntroductionLabel() -> UILabel {
        let label = UILabel()
        label.text = "「達成目標」と「やること」を登録して、\n一つずつ達成していきましょう！"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }
    
}


// MARK: - GoalCollectionViewCellDelegate

extension GoalsEditingViewController: GoalCollectionViewCellDelegate {
    func getGoalData(row: Int) {
        viewModel.getGoalData(row: row)
    }
    
    func transtionToRegistrationView(num: Int) {
        let documentID = viewModel.getDocumentID(row: num)
        let vc = TodoRegistrationViewController(parentDocumentID: documentID)
        navigationController?.pushViewController(vc, animated: true)
    }
    
}


// MARK: - TodoViewDelegate

extension GoalsEditingViewController: TodoViewDelegate {
    func getTodoData(section: Int, row: Int) {
        viewModel.getTodoData(section: section, row: row)
    }
}


// MARK: - NetworkErrorViewDelegate

extension GoalsEditingViewController: NetworkErrorViewDelegate {
    func retryAction() {
        viewModel.getInitialData()
    }
}


// MARK: - UICollectionViewDelegate

extension GoalsEditingViewController: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentOffsetY = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.height
        let distanceToBottom = maximumOffset - currentOffsetY

        if distanceToBottom < 200 {
            viewModel.getGoalData(isInitialDataFetch: false)
        }
    }
}
