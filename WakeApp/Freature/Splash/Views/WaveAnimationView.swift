//
//  WaveAnimationView.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/06/24.
//

import UIKit

public class WaveAnimationView: UIView {

    private let frontWaveLine: UIBezierPath = UIBezierPath()
    private let backWaveLine: UIBezierPath = UIBezierPath()
    
    private let frontWaveLayer: CAShapeLayer = CAShapeLayer()
    private let backWaveSubLayer: CAShapeLayer = CAShapeLayer()
    
    private var timer = Timer()
    
    private var drawSeconds: CGFloat = 0.0
    private var drawElapsedTime: CGFloat = 0.0
    
    private var width: CGFloat
    private var height: CGFloat
    private var xAxis: CGFloat
    private var yAxis: CGFloat
    
    open var waveDelay: CGFloat = 300.0 //0.0 .. about 500.0 are standard.
    
    open var frontColor: UIColor!
    open var backColor: UIColor!
    
    
    private override init(frame: CGRect) {
        self.width = frame.width
        self.height = frame.height
        self.xAxis = floor(height/3)
        self.yAxis = 0.0
        super.init(frame: frame)
    }
    
    public convenience init(frame: CGRect, color: UIColor) {
        self.init(frame: frame)
        self.frontColor = color
        self.backColor = color
    }
    
    //Possible to set fillColors separately.
    public convenience init(frame: CGRect, frontColor: UIColor, backColor: UIColor) {
        self.init(frame: frame)
        self.frontColor = frontColor
        self.backColor = backColor
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    public override func draw(_ rect: CGRect) {
        wave(layer: backWaveSubLayer, path: backWaveLine, color: backColor, delay: waveDelay)
        wave(layer: frontWaveLayer, path: frontWaveLine, color: frontColor, delay: 0)
    }
    
    //Start wave Animation
    open func startAnimation() {
        timer = Timer.scheduledTimer(timeInterval: 0.035, target: self, selector: #selector(waveAnimation), userInfo: nil, repeats: true)
    }
    
    //MARK: Please be sure to call this method at ViewDidDisAppear or deinit in ViewController.
    //If it isn't called, Memory Leaks occurs by Timer
    open func stopAnimation() {
        timer.invalidate()
    }
    
    @objc private func waveAnimation() {
        self.setNeedsDisplay()
    }
    
    
    @objc private func wave(layer: CAShapeLayer, path: UIBezierPath, color: UIColor, delay:CGFloat) {
        path.removeAllPoints()
        drawWave(layer: layer, path: path, color: color, delay: delay)
        drawSeconds += 0.009
        let pi = CGFloat(Double.pi)*2
        drawElapsedTime = drawSeconds*pi
        if drawElapsedTime >= pi {
            drawSeconds = 0.0
            drawElapsedTime = 0.0
        }
    }
    
    private func drawWave(layer: CAShapeLayer,path: UIBezierPath,color: UIColor,delay:CGFloat) {
        drawSin(path: path,time: drawElapsedTime, delay: delay)
        path.addLine(to: CGPoint(x: width+10, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.close()
        
        layer.fillColor = color.cgColor
        layer.path = path.cgPath
        self.layer.insertSublayer(layer, at: 0)
    }
    
    private func drawSin(path: UIBezierPath, time: CGFloat, delay: CGFloat) {
        
        let unit:CGFloat = 30.0
        let scaleForPeriod:CGFloat = 100.0
        var x = time
        var y = sin(x)
        let start = CGPoint(x: yAxis, y: unit*y+xAxis)
        
        path.move(to: start)
        
        var i = yAxis
        while i <= width+10 {
            x = time+(-yAxis+i)/scaleForPeriod
            y = sin(x - delay)
            
            path.addLine(to: CGPoint(x: i, y: unit*y+xAxis))
            
            i += 10
        }
        
    }
    
}
