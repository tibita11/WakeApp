//
//  StartingPageViewController.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/05/28.
//

import UIKit

class MainPageViewController: UIPageViewController {
    private let pageData: [(imageName: String, title: String)] = [
        ("StartingPage1", "1. 努力の方向性を定める"),
        ("StartingPage2", "2. 今やるべきことだけに熱中する"),
        ("StartingPage3", "3. 達成した目標を経験として積む")
    ]
    private var controllers = [UIViewController]()
    
    
    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpPageViewController()
        UIPageControl.appearance().pageIndicatorTintColor = .systemGray6
        UIPageControl.appearance().currentPageIndicatorTintColor = Const.mainBlueColor
    }
    
    
    // MARK: - Action
    
    private func setUpPageViewController() {
        pageData.forEach {
            let introductionVC = IntroductionViewController(image: UIImage(named: $0.imageName)!, title: $0.title)
            controllers.append(introductionVC)
        }
        setViewControllers([controllers[0]], direction: .forward, animated: true)
        self.dataSource = self
        self.delegate = self
    }
    
}


// MARK: - UIPageViewControllerDataSource

extension MainPageViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        //左スライド
        if let index = controllers.firstIndex(of: viewController), index > 0 {
            return controllers[index - 1]
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        // 右スライド
        if let index = controllers.firstIndex(of: viewController), index < controllers.count - 1 {
            return controllers[index + 1]
        }
        return nil
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        controllers.count
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        0
    }
}
