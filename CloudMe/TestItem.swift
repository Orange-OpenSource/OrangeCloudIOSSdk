/*
 Copyright (C) 2016 Orange
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation

let labelFontSize = CGFloat (16)
let labelFont = UIFont(name: "HelveticaNeue-Light", size: labelFontSize)

let buttonFontSize = CGFloat (16)
let buttonFont = UIFont(name: "HelveticaNeue-Light", size: buttonFontSize)

let titleFontSize = CGFloat (20)
let titleFont = UIFont(name: "HelveticaNeue-Light", size: titleFontSize)

class TestItem : UIView {
    let label = UILabel ()
    let ledState = UIImageView ()
    let durationLabel = UILabel ()
    var duration : NSTimeInterval = 0 {
        didSet {
            let sec = floor(duration * 10)/10.0
            let average = floor(stats.average (name)*10)/10.0
            durationLabel.text = "\(sec)s (\(average)s)"
        }
    }
    var closure : TestFunc?
    var name : String {
        get { return label.text ?? "no name"}
    }
    override init (frame: CGRect) {
        super.init(frame: frame)
        let width = frame.size.width
        let height = frame.size.height
        let ledWidth = CGFloat(12)
        let labelWidth = width * 0.5 - ledWidth / 2
        
        label.frame = CGRectMake(0, 0, labelWidth, height)
        label.textColor = UIColor (white: 0.2, alpha: 1)
        label.font = labelFont
        label.textAlignment = .Right
        addSubview(label)
        
        ledState.frame = CGRectMake (labelWidth+ledWidth/2, (height - ledWidth)/2, ledWidth, ledWidth)
        ledState.image = UIImage (named: "led.gray")
        addSubview(ledState)
        
        durationLabel.frame = CGRectMake(labelWidth+2*ledWidth, 0, width - labelWidth - 2 * ledWidth, height)
        durationLabel.textColor = UIColor (white: 0.4, alpha: 1)
        durationLabel.font = labelFont
        durationLabel.textAlignment = .Left
        durationLabel.text = ""
        addSubview(durationLabel)
        
    }
    
    var state : TestState = .Pending {
        didSet {
            if ledState.isAnimating() {
                ledState.stopAnimating()
            }
            switch state {
            case .InProgress:
                if let img1 = UIImage (named: "led.gray.png"), let img2 = UIImage (named: "led.yellow.png") {
                    ledState.animationImages = [ img1, img2 ]
                    ledState.animationDuration = 1
                    ledState.startAnimating()
                }
            case .Pending:
                ledState.image = UIImage (named: "led.gray.png")
            case .Failed:
                ledState.image = UIImage (named: "led.red.png")
            case .Partial:
                ledState.image = UIImage (named: "led.yellow.png")
            case .Succeeded:
                ledState.image = UIImage (named: "led.green.png")
            }
        }
    }
    
    required init(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
