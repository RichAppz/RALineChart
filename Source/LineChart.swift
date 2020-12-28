//
//  LineChart.swift
//  RALineChart
//
//  Created by Rich Mucha on 28/12/2020.
//

import Foundation
import UIKit

public class LineChart: UIView {
    
    //==========================================
    // MARK: Properties
    //==========================================
    
    /// Layers within the chart
    private let dataLayer: CALayer = CALayer()
    private let gradientLayer: CAGradientLayer = CAGradientLayer()
    private let mainLayer: CALayer = CALayer()
    private let scrollView: UIScrollView = UIScrollView()
    private let gridLayer: CALayer = CALayer()
    
    /// An array of CGPoint on dataLayer coordinate system that the main line will go through.
    /// These points will be calculated from dataSet array
    private var dataPoints: [CGPoint]?
    
    /// Gesture
    private var gestureRecognizer: UIGestureRecognizer?
    private var yGestureBar: UIView?
    private var xGestureBar: UIView?
    
    /// The top most horizontal line in the chart will be 10% higher than the highest value in the chart
    private let topHorizontalLine: CGFloat = 110.0 / 100.0
    private let textLayerWidth: CGFloat = 50
    private var requiresLayout = true
    
    //==========================================
    // MARK: Settings
    //==========================================
    
    // Mark: Padding
    private var lineGap: CGFloat {
        return bounds.width/CGFloat(dataSet?.count ?? 0)
    }
    
    public var topSpace: CGFloat = 10
    public var bottomSpace: CGFloat = 30
    public var isCurved: Bool = false
    
    /// Active or desactive animation on dots
    public var animateDots: Bool = false
    
    /// Active or desactive dots
    public var showDots: Bool = false
    public var showGridLines: Bool = false
    public var showGradient: Bool = false
    public var showXLabels: Bool = false
    public var showBELabels: Bool = false
    
    /// Colors
    public var lineColor: UIColor? = .black
    public var touchColor: UIColor? = .black
    public var gradientColor: UIColor? = .black
    
    /// Dot Radius
    public var innerRadius: CGFloat = 8
    public var outerRadius: CGFloat = 12

    /// Dataset
    public var dataSet: [Dataset]? {
        didSet {
            requiresLayout = true
            setNeedsLayout()
        }
    }
    
    public var isTouchable: Bool = false {
        didSet {
            if let recognizer = gestureRecognizer, !isTouchable {
                removeGestureRecognizer(recognizer)
                gestureRecognizer = nil
            } else {
                let gesture = UIPanGestureRecognizer(target: self, action: #selector(panGesture))
                addGestureRecognizer(gesture)
                gestureRecognizer = gesture
            }
        }
    }
    
    //==========================================
    // MARK: Callback
    //==========================================
    
    public var callback: ((Dataset?) -> Void)?
    
    //==========================================
    // MARK: Initialisation
    //==========================================
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //==========================================
    // MARK: Lifecycle
    //==========================================
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if !requiresLayout { return }
        
        scrollView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        
        if let dataSet = dataSet, dataSet.count > 1 {
            scrollView.contentSize = bounds.size
            mainLayer.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
            dataLayer.frame = CGRect(x: 0, y: topSpace, width: frame.width, height: frame.height - topSpace - bottomSpace)
            gradientLayer.frame = dataLayer.frame
            dataPoints = convertdataSetToPoints(entries: dataSet)
            gridLayer.frame = CGRect(x: 0, y: topSpace, width: frame.width, height: frame.height - topSpace - bottomSpace)
            clean()
            drawHorizontalLines()
            
            isCurved ? drawCurvedChart() : drawChart()
            maskGradientLayer()
        }
    }
    
    //==========================================
    // MARK: Helpers
    //==========================================
    
    public func setupView() {
        mainLayer.addSublayer(dataLayer)
        scrollView.layer.addSublayer(mainLayer)
        
        if let gradientColor = gradientColor, showGradient {
            gradientLayer.colors = [gradientColor.cgColor, UIColor.clear.cgColor]
            scrollView.layer.addSublayer(gradientLayer)
        }
        
        if showGridLines {
            layer.addSublayer(gridLayer)
        }
        
        addSubview(scrollView)
    }
    
    public func clean() {
        mainLayer.sublayers?.forEach({
            if $0 is CATextLayer {
                $0.removeFromSuperlayer()
            }
        })
        dataLayer.sublayers?.forEach({$0.removeFromSuperlayer()})
        gridLayer.sublayers?.forEach({$0.removeFromSuperlayer()})
        
        xGestureBar?.removeFromSuperview()
        yGestureBar?.removeFromSuperview()
        xGestureBar = nil
        yGestureBar = nil
    }
    
    //==========================================
    // MARK: Private Helpers
    //==========================================
    
    @objc func panGesture(gestureRecognizer: UIPanGestureRecognizer) {
        requiresLayout = false
        
        let touchLocation = gestureRecognizer.location(in: self)
        if let xGestureBar = xGestureBar, let yGestureBar = yGestureBar {
            let y = getYLocation(point: touchLocation)
            xGestureBar.frame.origin.y = y + topSpace
            yGestureBar.frame.origin.x = touchLocation.x
        } else {
            let yView = UIView()
            yView.backgroundColor = touchColor?.withAlphaComponent(0.6)
            var location = touchLocation.x
            if location > bounds.width {
                location = bounds.width-1
            }
            yView.frame = CGRect(x: location, y: 0, width: 1, height: bounds.height)
            addSubview(yView)
            
            yGestureBar = yView
            
            let xView = UIView()
            xView.backgroundColor = touchColor?.withAlphaComponent(0.6)
            xView.frame = CGRect(x: 0, y: touchLocation.y, width: bounds.width, height: 1)
            addSubview(xView)
            
            xGestureBar = xView
        }
    }
    
    private func getYLocation(point: CGPoint) -> CGFloat {
        let percent: Double = Double(point.x/bounds.width)
        
        // Rounded the percentage to the nearest whole value
        let roundedPercentage = round(Double(dataSet?.count ?? 0) * percent)
        var idx = Int(roundedPercentage)
        while idx >= dataSet?.count ?? 0 { idx -= 1 }
        if idx < 0 { idx = 0 }
        
        if let data = dataPoints?[idx], let set = dataSet?[idx] {
            callback?(set)
            return data.y
        }
        return point.y
    }
    
    /**
     Convert an array of DataSet to an array of CGPoint on dataLayer coordinate system
     */
    private func convertdataSetToPoints(entries: [Dataset]) -> [CGPoint] {
        if let max = entries.max()?.value,
            let min = entries.min()?.value {
            
            var result: [CGPoint] = []
            let minMaxRange: CGFloat = CGFloat(max - min) * topHorizontalLine
            
            for i in 0..<entries.count {
                let height = dataLayer.frame.height * (1 - ((CGFloat(entries[i].value) - CGFloat(min)) / minMaxRange))
                let point = CGPoint(x: CGFloat(i)*lineGap, y: height)
                result.append(point)
            }
            return result
        }
        return []
    }
    
    /**
     Draw the chart
     */
    private func drawChart() {
        if let dataPoints = dataPoints,
            dataPoints.count > 0,
            let path = dataPath {
            
            let lineLayer = CAShapeLayer()
            lineLayer.path = path.cgPath
            lineLayer.strokeColor = lineColor?.cgColor
            lineLayer.fillColor = UIColor.clear.cgColor
            dataLayer.addSublayer(lineLayer)
        }
    }
    
    /**
     Create a zigzag bezier path that connects all points in dataPoints
     */
    private var dataPath: UIBezierPath? {
        guard let dataPoints = dataPoints, dataPoints.count > 0 else { return nil }
        
        let path = UIBezierPath()
        path.move(to: dataPoints[0])
        
        dataPoints.forEach {
            path.addLine(to: $0)
        }
        return path
    }
    
    /**
     Draw a curved line connecting all points in dataPoints
     */
    private func drawCurvedChart() {
        guard let dataPoints = dataPoints, dataPoints.count > 0 else { return }
        dataLayer.sublayers?.forEach({ (layer) in
            layer.removeFromSuperlayer()
        })
        
        if let path = CurveAlgorithm.shared.createCurvedPath(dataPoints) {
            let lineLayer = CAShapeLayer()
            lineLayer.path = path.cgPath
            lineLayer.strokeColor = lineColor?.cgColor
            lineLayer.fillColor = UIColor.clear.cgColor
            dataLayer.addSublayer(lineLayer)
            
            let followLayer = CAShapeLayer()
            followLayer.path = path.cgPath
            followLayer.lineWidth = 1.8
            followLayer.strokeColor = lineColor?.withAlphaComponent(0.8).cgColor
            followLayer.fillColor = UIColor.clear.cgColor
            dataLayer.addSublayer(followLayer)
            
            lineLayer.animate()
            followLayer.pulseAnimation()
        }
    }
    
    /// Create a gradient layer below the line that connecting all dataPoints
    private func maskGradientLayer() {
        gradientLayer.sublayers?.forEach({ (layer) in
            layer.removeFromSuperlayer()
        })
        
        if let dataPoints = dataPoints,
            dataPoints.count > 0 {
            
            let path = UIBezierPath()
            path.move(to: CGPoint(x: dataPoints[0].x, y: dataLayer.frame.height))
            path.addLine(to: dataPoints[0])
            if isCurved,
                let curvedPath = CurveAlgorithm.shared.createCurvedPath(dataPoints) {
                path.append(curvedPath)
            } else if let straightPath = dataPath {
                path.append(straightPath)
            }
            path.addLine(to: CGPoint(x: dataPoints[dataPoints.count-1].x, y: dataLayer.frame.height))
            path.addLine(to: CGPoint(x: dataPoints[0].x, y: dataLayer.frame.height))
            
            let maskLayer = CAShapeLayer()
            maskLayer.path = path.cgPath
            maskLayer.fillColor = gradientColor?.cgColor
            maskLayer.strokeColor = UIColor.clear.cgColor
            maskLayer.lineWidth = 0.0
            
            gradientLayer.mask = maskLayer
            maskLayer.animate()
        }
    }
    
    /**
     Create horizontal lines (grid lines) and show the value of each line
     */
    private func drawHorizontalLines() {
        guard let dataSet = dataSet else { return }
        
        var gridValues: [CGFloat]? = nil
        if dataSet.count < 4 && dataSet.count > 0 {
            gridValues = [0, 1]
        } else if dataSet.count >= 4 {
            gridValues = [0, 0.25, 0.5, 0.75, 1]
        }
        
        if let gridValues = gridValues {
            for value in gridValues {
                let height = value * gridLayer.frame.size.height
                
                let path = UIBezierPath()
                path.move(to: CGPoint(x: 0, y: height))
                path.addLine(to: CGPoint(x: gridLayer.frame.size.width, y: height))
                
                let lineLayer = CAShapeLayer()
                lineLayer.path = path.cgPath
                lineLayer.fillColor = UIColor.clear.cgColor
                lineLayer.strokeColor = #colorLiteral(red: 0.2784313725, green: 0.5411764706, blue: 0.7333333333, alpha: 1).cgColor
                lineLayer.lineWidth = 0.5
                if (value > 0.0 && value < 1.0) {
                    lineLayer.lineDashPattern = [4, 4]
                }
                
                gridLayer.addSublayer(lineLayer)
                
                var minMaxGap:CGFloat = 0
                var lineValue:Int = 0
                if let max = dataSet.max()?.value,
                    let min = dataSet.min()?.value {
                    minMaxGap = CGFloat(max - min) * topHorizontalLine
                    lineValue = Int((1-value) * minMaxGap) + Int(min)
                }
                
                let textLayer = CATextLayer()
                textLayer.frame = CGRect(x: 4, y: height, width: 50, height: 16)
                textLayer.foregroundColor = #colorLiteral(red: 0.5019607843, green: 0.6784313725, blue: 0.8078431373, alpha: 1).cgColor
                textLayer.backgroundColor = UIColor.clear.cgColor
                textLayer.contentsScale = UIScreen.main.scale
                textLayer.font = CTFontCreateWithName(UIFont.systemFont(ofSize: 0).fontName as CFString, 0, nil)
                textLayer.fontSize = 12
                textLayer.string = "\(lineValue)"
                
                gridLayer.addSublayer(textLayer)
            }
        }
    }
    
}

//==========================================
// MARK: CAShapeLayer+Extension
//==========================================

private extension CAShapeLayer {
    
    func animate() {
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = 0
        animation.duration = 1.8
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        animation.fillMode = CAMediaTimingFillMode.forwards
        add(animation, forKey: "MyAnimation")
    }
    
    func pulseAnimation() {
        let duration: CFTimeInterval = 1.8
        
        let end = CABasicAnimation(keyPath: "strokeEnd")
        end.fromValue = 0
        end.toValue = 1.0175
        end.beginTime = 0
        end.duration = duration
        end.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        end.fillMode = CAMediaTimingFillMode.forwards
        
        let begin = CABasicAnimation(keyPath: "strokeStart")
        begin.fromValue = 0
        begin.toValue = 1.0175
        begin.beginTime = duration * 0.15
        begin.duration = duration
        begin.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        begin.fillMode = CAMediaTimingFillMode.backwards
        
        let group = CAAnimationGroup()
        group.animations = [end, begin]
        group.duration = duration
        
        strokeEnd = 1
        strokeStart = 1
        add(group, forKey: "move")
    }
    
}
