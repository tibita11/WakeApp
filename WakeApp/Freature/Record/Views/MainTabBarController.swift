//
//  MainTabBarController.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/06/23.
//

import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUp()
        setUpNavigationButton()
    }
    
    private func setUp() {
        let recordVC = RecordViewController()
        recordVC.tabBarItem = UITabBarItem(title: "記録する", image: UIImage(systemName: "pencil"), tag: 0)
        let profileVC = ProfileViewController()
        profileVC.tabBarItem = UITabBarItem(title: "プロフィール", image: UIImage(systemName: "person"), tag: 1)
        viewControllers = [recordVC, profileVC]
    }
    
    private func setUpNavigationButton() {
        let settingsButton = UIBarButtonItem(image: UIImage(systemName: "list.bullet"),
                                             style: .plain,
                                             target: self,
                                             action: #selector(tapSettingsButton))
        settingsButton.tintColor = UIColor.white
        navigationItem.rightBarButtonItem = settingsButton
    }
    
    @objc private func tapSettingsButton() {
        let vc = ProfileSettingsTableViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}
