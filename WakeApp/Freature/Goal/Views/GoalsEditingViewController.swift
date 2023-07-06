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
    
    private var viewModel: GoalsEditingViewModel!
    private let disposeBag = DisposeBag()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUp()
    }
    
    
    // MARK: - Action
    
    private func setUp() {
        // 別の方法でセルの大きさを変えてみる
        collectionView.register(UINib(nibName: "GoalCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "GoalCollectionViewCell")
        
        viewModel = GoalsEditingViewModel()
        
        // itemをcollectionViewに表示
        viewModel.outputs.goalDataDriver
            .drive(collectionView.rx.items(cellIdentifier: "GoalCollectionViewCell", cellType: GoalCollectionViewCell.self)) { [weak self] row, element, cell in
                cell.titleLabel.text = element.title
                cell.setBaseViewWidth(to: self!.collectionView.bounds.width)
                
                // Todoの設定
                let total = 3
                let itemHeight = 130
                let space = 10
                cell.setBaseViewHeight(to: CGFloat((total * itemHeight) + (2 * space)))

                for num in 0...total - 1 {
                    let todoView = TodoView()
                    todoView.frame = CGRect(x: 0,
                                            y: num * itemHeight + 10,
                                            width: Int(self!.collectionView.bounds.width),
                                            height: itemHeight)
                    cell.baseView.addSubview(todoView)
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
        
        // 初期データの取得
        viewModel.getGoalData()
    }
    
    /// 目標追加画面に遷移
    @IBAction func tapAdditionButton(_ sender: Any) {
        let vc = GoalRegistrationViewController()
        present(vc, animated: true)
    }
    
    /// GoalDataを再取得
    @objc private func tapRetryButton() {
        viewModel.getGoalData()
    }
    
}
