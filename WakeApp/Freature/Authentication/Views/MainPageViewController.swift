//
//  StartingPageViewController.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/05/28.
//

import UIKit

class MainPageViewController: UIPageViewController {
    private var controllers = [UIViewController]()
    private var pageControl: UIPageControl!
    
    
    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpPageViewController()
    }
    
    
    // MARK: - Action
    
    /// PageViewControllerの設定
    private func setUpPageViewController() {
        for number in 1...3 {
            var introductionPage: IntroductionPage!
            switch number {
            case 1:
                introductionPage = IntroductionPage.page1
            case 2:
                introductionPage = IntroductionPage.page2
            case 3:
                introductionPage = IntroductionPage.page3
            default:
                break
            }
            let introduction = IntroductionViewController(image: UIImage(named: introductionPage.getImageName())!, title: introductionPage.getTitle())
            controllers.append(introduction)
        }
        setViewControllers([controllers[0]], direction: .forward, animated: true)
        self.dataSource = self
        self.delegate = self
    }
    
    /// UIPageControlの設定
    func setUpPageControl() {
        pageControl = UIPageControl(frame: CGRect(x: 0, y: self.view.bounds.height - 100, width: self.view.bounds.width, height: 100))
        pageControl.numberOfPages = controllers.count
        pageControl.pageIndicatorTintColor = .systemGray6
        pageControl.currentPageIndicatorTintColor = Const.mainBlueColor
        pageControl.isUserInteractionEnabled = false
        self.view.addSubview(pageControl)
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
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        // ページ数を可視化
        if completed {
            guard let currentPageVC = pageViewController.viewControllers?.first,
                  let index = controllers.firstIndex(of: currentPageVC) else {
                return
            }
            pageControl.currentPage = index
        }
    }
}


// MARK: - IntroductionPage

enum IntroductionPage {
    case page1
    case page2
    case page3
    
    func getTitle() -> String {
        switch self {
        case .page1:
            return "1. 努力の方向性を定める"
        case .page2:
            return "2. 今やるべきことだけに熱中する"
        case .page3:
            return "3. 達成した目標を経験として積む"
        }
    }
    
    func getImageName() -> String {
        switch self {
        case .page1:
            return "StartingPage1"
        case .page2:
            return "StartingPage2"
        case .page3:
            return "StartingPage3"
        }
    }
}
