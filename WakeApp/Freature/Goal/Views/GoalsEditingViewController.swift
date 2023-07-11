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
            networkErrorView.layer.cornerRadius = 15
        }
    }
    @IBOutlet weak var retryButton: UIButton! {
        didSet {
            retryButton.addTarget(self, action: #selector(tapRetryButton), for: .touchUpInside)
        }
    }
    @IBOutlet weak var introductionView: UIView!
    
    private var viewModel: GoalsEditingViewModel!
    private let disposeBag = DisposeBag()
    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        return dateFormatter
    }()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUp()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 初期データの取得
        viewModel.getGoalData()
    }
    
    
    // MARK: - Action
    
    private func setUp() {
        // 別の方法でセルの大きさを変えてみる
        collectionView.register(UINib(nibName: "GoalCollectionViewCell", bundle: nil),
                                forCellWithReuseIdentifier: "GoalCollectionViewCell")
        
        viewModel = GoalsEditingViewModel()
        
        // itemをcollectionViewに表示
        viewModel.outputs.goalDataDriver
            .do(onNext: { [weak self] items in
                if items.isEmpty {
                    self?.introductionView.isHidden = false
                } else {
                    self?.introductionView.isHidden = true
                }
            })
            .drive(collectionView.rx.items(cellIdentifier: "GoalCollectionViewCell",
                                           cellType: GoalCollectionViewCell.self)) { [weak self] row, element, cell in
                guard let self else { return }
                cell.titleLabel.text = element.title
                cell.startDateLabel.text = dateFormatter.string(from: element.startDate)
                cell.endDateLabel.text = dateFormatter.string(from: element.endDate)
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
                case 1:
                    cell.statusLabel.text = "達成"
                    cell.statusLabel.textColor = UIColor.red
                default:
                    break
                }
                
                cell.setBaseViewWidth(to: collectionView.bounds.width)
                
                // Todoの設定
                let total = element.todos.count
                let itemHeight = 130
                let space = 10
                cell.setBaseViewHeight(to: CGFloat((total * itemHeight) + (2 * space)))
                
                if total != 0 {
                    for num in 0...total - 1 {
                        let todoView = TodoView()
                        todoView.titleLabel.text = element.todos[num].title
                        todoView.frame = CGRect(x: 0,
                                                y: num * itemHeight + 10,
                                                width: Int(collectionView.bounds.width),
                                                height: itemHeight)
                        cell.baseView.addSubview(todoView)
                    }
                }
                
            }
            .disposed(by: disposeBag)
        
        // オフライン時の再試行ボタン表示
        viewModel.outputs.isHiddenErrorDriver
            .drive(onNext: { [weak self] bool in
                self?.networkErrorView.isHidden = bool
            })
            .disposed(by: disposeBag)
        
        // ネットワークエラーアラート表示
        viewModel.outputs.networkErrorDriver
            .drive(onNext: { [weak self] in
                guard let self else { return }
                present(createNetworkErrorAlert(), animated: true)
            })
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
        
    }
    
    /// 目標追加画面に遷移
    @IBAction func tapAdditionButton(_ sender: Any) {
        let vc = GoalRegistrationViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    /// GoalDataを再取得
    @objc private func tapRetryButton() {
        viewModel.getGoalData()
    }
    
}


// MARK: - GoalCollectionViewCellDelegate

extension GoalsEditingViewController: GoalCollectionViewCellDelegate {
    func getDocumentID(num: Int) {
        let documentID = viewModel.getDocumentID(num: num)
        viewModel.getGoalData(documentID: documentID)
    }
    
    func transtionToRegistrationView(num: Int) {
        let documentID = viewModel.getDocumentID(num: num)
        let vc = TodoRegistrationViewController(documentID: documentID)
        navigationController?.pushViewController(vc, animated: true)
    }
    
}
