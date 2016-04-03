//
//  STShineLabel.swift
//  
//
//  Created by Strong on 16/3/30.
//
//

import UIKit

class STShineLabel: UILabel {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

    var shineDuration : CFTimeInterval = 0
    var fadeoutDuration : CFTimeInterval = 0
    var autoStart: Bool = false
    var shining : Bool {
        get {
            return !(self.displaylink!.paused)
        }
    }
    var visible : Bool {
        get {
            return (self.fadeOut == false)
        }
    }
    
    private var attributedString: NSMutableAttributedString?
    private var characterAnimationDurtions = [CFTimeInterval]()
    private var characterAnimationDelays = [CFTimeInterval]()
    private var displaylink: CADisplayLink?
    private var beginTime: CFTimeInterval = 0
    private var endTime: CFTimeInterval = 0
    private var fadeOut: Bool
    private var completion: (() -> Void)?
    
    override internal var text: String? {
        set {
            super.text = newValue
            attributedText = NSMutableAttributedString(string: newValue!)
            
        }
        get {
            return super.text
        }
    }
    
    override internal var attributedText: NSAttributedString? {
        set {
            attributedString = self.initialAttributedString(attributedString: newValue)
            super.attributedText = newValue
            
            for index in 0...newValue!.length - 1 {
                let delay = Double(arc4random_uniform(UInt32(shineDuration / 2 * 100))) / 100.0
                characterAnimationDelays.insert(delay, atIndex: index)
                let remain = shineDuration - delay
//                characterAnimationDurtions[index] = Double(arc4random_uniform(UInt32(remain * 100))) / 100.0
                characterAnimationDurtions.insert(Double(arc4random_uniform(UInt32(remain * 100))) / 100.0, atIndex: index)
            }
        }
        get {
            return super.attributedText
        }
    }
    convenience init() {
        self.init(frame:CGRect.zero)
    }
    
    override init(frame: CGRect) {
        shineDuration = 2.5
        fadeoutDuration = 2.5
        autoStart = false
        fadeOut = true
        
        super.init(frame: frame)
        self.textColor = UIColor.whiteColor()
        displaylink = CADisplayLink(target: self, selector:#selector(STShineLabel.updateAttributedString))
        displaylink!.paused = true
        displaylink!.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToWindow() {
        if (self.window != nil) && self.autoStart {
            self.shine()
        }
    }

    internal func updateAttributedString() {
        let now = CACurrentMediaTime()
        for index in 0...attributedString!.length - 1 {
//            let indexString = attributedString!.string.characters(index)
//            NSCharacterSet.whitespaceCharacterSet().characterIsMember(indexString) {
//                continue
//            }
            
            attributedString!.enumerateAttribute(NSForegroundColorAttributeName, inRange: NSMakeRange(index, 1), options: NSAttributedStringEnumerationOptions(rawValue: 0), usingBlock: { (value, range, stop) in
            
                let currentAlpha = CGColorGetAlpha(value?.CGColor)
                let checkAlpha = (self.fadeOut && (currentAlpha > 0)) || (!self.fadeOut && (currentAlpha < 1))
                let shouldUpdateAlpha : Bool = checkAlpha || (now - self.beginTime) >= self.characterAnimationDelays[index]
                if !shouldUpdateAlpha {
                    return
                }
                
                var percentage = (now - self.beginTime - self.characterAnimationDelays[index]) / (self.characterAnimationDurtions[index])
                if (self.fadeOut) {
                    percentage = 1 - percentage
                }
                
                let color = self.textColor.colorWithAlphaComponent(CGFloat(percentage))
                self.attributedString!.addAttributes([NSForegroundColorAttributeName : color], range: range)
            })
        }
        
        super.attributedText = attributedString
        if now > endTime {
            displaylink!.paused = true
            if self.completion != nil {
                self.completion!()
            }
        }
    }
    
    
    internal func initialAttributedString(attributedString attributedString: NSAttributedString?) -> NSMutableAttributedString? {
        if attributedString == nil {
            return nil
        }
        
        let mutableAttributedString = attributedString!.mutableCopy() as! NSMutableAttributedString
        let color = textColor.colorWithAlphaComponent(0)
        mutableAttributedString.addAttributes([NSForegroundColorAttributeName : color], range: NSMakeRange(0, mutableAttributedString.length))
        
        return mutableAttributedString
    }
    
    func shine() {
        shineWithCompletion(nil)
    }
    
    func shineWithCompletion(completion: (() -> Void)?) {
        if (!self.shining) && (self.fadeOut) {
            self.completion = completion
            fadeOut = false
            startAnimation(duration: fadeoutDuration)
        }
    }
    
    func fadeout() {
        fadeOutWithCompletion(nil)
    }
    
    func fadeOutWithCompletion(completion: (() -> Void)?) {
        if (!self.shining) && (!self.fadeOut) {
            self.completion = completion
            fadeOut = true
            startAnimation(duration: fadeoutDuration)
        }
    }
    
    func startAnimation(duration duration: CFTimeInterval) {
        beginTime = CACurrentMediaTime()
        endTime = beginTime + shineDuration
        displaylink!.paused = false
    }
}
