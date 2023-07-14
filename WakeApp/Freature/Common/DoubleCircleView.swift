//
//  DoubleCircleView.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/07/04.
//

import UIKit

class DoubleCircleView: UIView {
    
    var innerCircleColor: UIColor = .systemBackground
    var outerCircleColor: UIColor = Const.alphaMainBlueColor
    
    override func draw(_ rect: CGRect) {
        // 外側の円を描画
        let outerCirclePath = UIBezierPath(ovalIn: rect)
        outerCircleColor.setFill()
        outerCirclePath.fill()
        
        // 内側の円を描画
        // 外側の円と比較して、半径を小さくする
        let innerRect = rect.insetBy(dx: rect.width * 0.25, dy: rect.height * 0.25)
        let innerCirclePath = UIBezierPath(ovalIn: innerRect)
        innerCircleColor.setFill()
        innerCirclePath.fill()
    }
    
}
