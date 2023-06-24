//
//  TestViewController.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/06/23.
//

import UIKit

class SplashViewController: UIViewController {
    
    var wave: WaveAnimationView!
    
    
    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUp()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        wave.stopAnimation()
    }
    
    // MARK: - Action
    
    private func setUp() {
        view.backgroundColor = .systemBackground
        
        wave = WaveAnimationView(frame: self.view.frame, frontColor: Const.splashFrontColor, backColor: Const.mainBlueColor)
        view.addSubview(wave)
        wave.startAnimation()
        
        setUpImageView()
    }
    
    private func setUpImageView() {
        let image = UIImageView(image: UIImage(named: "AppIconWhite"))
        image.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(image)
        
        NSLayoutConstraint.activate([
            image.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            image.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            image.widthAnchor.constraint(equalToConstant: 100),
            image.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
}
