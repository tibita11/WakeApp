//
//  ProfileSettingsTableViewController.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/06/28.
//

import UIKit
import RxSwift
import RxCocoa

class ProfileSettingsTableViewController: UITableViewController {
    private let sections = [["プロフィールを編集する", "目標を編集する"],
                            ["広告非表示(¥300)"],
                            ["サインアウト", "退会する"]]
    
    private let viewModel = ProfileSettingsTableViewModel()
    private let disposeBag = DisposeBag()
    
    // MARK: - View Life Cycle
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "profileSettingsCell")
        setUpViewModel()
    }
    
    // MARK: - Action
    
    private func setUpViewModel() {
        viewModel.outputs.networkErrorAlertDriver
            .drive(onNext: { [weak self] in
                guard let self else { return }
                present(createNetworkErrorAlert(), animated: true)
            })
            .disposed(by: disposeBag)
        
        viewModel.outputs.errorAlertDriver
            .drive(onNext: { [weak self] error in
                guard let self else { return }
                present(createErrorAlert(title: error), animated: true)
            })
            .disposed(by: disposeBag)
        
        viewModel.outputs.navigateToStartingViewDriver
            .drive(onNext: { [weak self] in
                guard let self else { return }
                let vc = StartingViewController()
                navigationController?.viewControllers = [vc]
            })
            .disposed(by: disposeBag)
        
        viewModel.outputs.reloadData
            .drive(onNext: { [weak self] in
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)
        
    }
    
    private func createUnsubscribeAlert() -> UIAlertController {
        let title = "退会してよろしいですか。"
        let message = "退会するとあなたのアカウントはシステムから削除され、使用できなくなります。"
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "はい", style: .default) { [weak self] _ in
            self?.viewModel.unsubscribe()
        }
        let cancelAction = UIAlertAction(title: "いいえ", style: .cancel)
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        return alertController
    }
    
    private func createSignOutAlert() -> UIAlertController {
        let title = "サインアウトしてよろしいですか。"
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "はい", style: .default) { [weak self] _ in
            self?.viewModel.signOut()
        }
        let cancelAction = UIAlertAction(title: "いいえ", style: .cancel)
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        return alertController
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "profileSettingsCell", for: indexPath)
        var config = cell.defaultContentConfiguration()
        config.text = sections[indexPath.section][indexPath.row]
        cell.contentConfiguration = config
        cell.accessoryType = .none

        if indexPath.section == 1 && UserDefaults.standard.bool(forKey: Const.userDefaultKeyForPurchase) {
            cell.accessoryType = .checkmark
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == 0 {
            switch indexPath.row {
            case 0:
                let profileEditingVC = ProfileEditingViewController()
                navigationController?.pushViewController(profileEditingVC, animated: true)
            case 1:
                let goalsEditingVC = GoalsEditingViewController()
                navigationController?.pushViewController(goalsEditingVC, animated: true)
            default: break
            }
            
        } else if indexPath.section == 1 {
//            viewModel.purchase()
            let vc = SubscriptionViewController()
            self.navigationController?.pushViewController(vc, animated: true)
        } else if indexPath.section == 2 {
            switch indexPath.row {
            case 0:
                present(createSignOutAlert(), animated: true)
            case 1:
                present(createUnsubscribeAlert(), animated: true)
            default: break
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == 1 && UserDefaults.standard.bool(forKey: Const.userDefaultKeyForPurchase) {
            return nil
        }
        return indexPath
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 1 && UserDefaults.standard.bool(forKey: Const.userDefaultKeyForPurchase) {
            return false
        }
        return true
    }
}
