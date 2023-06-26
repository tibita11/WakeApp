//
//  TriangleView.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/06/26.
//

import UIKit

class TriangleView: UIView {
    
    override func draw(_ rect: CGRect) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.close()
        UIColor.systemBackground.setFill()
        path.fill()
    }
}
