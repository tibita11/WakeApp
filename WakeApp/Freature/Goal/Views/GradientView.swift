//
//  GradientView.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/07/14.
//

import UIKit

/// Viewのframeとlayerが連動するよう作成
class GradientView: UIView {
    
    var didLayoutSubView: ((CGRect) -> Void)?
    
    init() {
        super.init(frame: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // サブビューのレイアウトが終わったら呼ばれる
    override func layoutSubviews() {
        super.layoutSubviews()
        // クロージャーで外に通知
        didLayoutSubView?(bounds)
    }
}
