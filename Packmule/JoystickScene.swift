import SpriteKit
import UIKit
import CoreBluetooth
class JoystickScene: SKScene {
    
    let moveAnalogStick = AnalogJoystick(diameters: (300,50), colors: (UIColorFromRGB(rgbValue : 0xf2b807), UIColorFromRGB(rgbValue : 0xf40077)))
    //let moveAnalogStick = AnalogJoystick(diameters: (300,100), images: (UIImage(named: "image_button_bg"), UIImage(named: "image_button")))
    let arduinoTxt = SKLabelNode(text: "")
    let infoText = SKLabelNode(text: "")
    var engagedEStop:Bool? = nil
    
    override func didMove(to view: SKView) {
        /* Setup your scene here */
        //MARK: Handlers begin
        addLabels(view: view)
        moveAnalogStick.trackingHandler = {[unowned self] data in
            if UserDefaults.standard.bool(forKey: "manual_mode") {
                self.infoText.text = data.description
                _ = MainViewController.sendMessage(message: "\(data.sendingMessage)\n")
            }
            else if !self.engagedEStop! {
                self.moveAnalogStick.substrate.color = UIColor.green.darker(by: 50)!
            }
            else {
                self.moveAnalogStick.substrate.color = UIColor.red.darker(by: 30)!
            }
        }
        
        moveAnalogStick.stopHandler = {
            if UserDefaults.standard.bool(forKey: "manual_mode"){
                self.infoText.text = "Stopped"
                _ = MainViewController.sendMessage(message: "127127\n")
            }
            else if self.moveAnalogStick.cancelled {
                let currentColor = self.moveAnalogStick.substrate.color
                self.moveAnalogStick.substrate.color = currentColor.lighter(by: 30)!
                return
            }
            else if !self.engagedEStop! {
                self.engagedEStop = true
                self.moveAnalogStick.substrate.color = UIColor.red
                self.infoText.text = "Stopped"
                _ = MainViewController.sendMessage(message: "e\n")
            }
            else {
                self.engagedEStop = false
                self.infoText.text = "Following"
                self.moveAnalogStick.substrate.color = UIColor.green.darker(by: 20)!
                _ = MainViewController.sendMessage(message: "d\n")
            }
        }
        
        //MARK: Handlers end
        view.isMultipleTouchEnabled = true
    }
    func addLabels (view: SKView) {
        moveAnalogStick.position = CGPoint(x: frame.width / 2, y: frame.height * 0.4)
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: frame.width / 2, y: frame.height * 0.6), radius: CGFloat(150), startAngle: CGFloat(0), endAngle:CGFloat(Double.pi * 2), clockwise: true)
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = circlePath.cgPath
        
        //change the fill color
        shapeLayer.fillColor = UIColor.clear.cgColor
        //you can change the stroke color
        shapeLayer.strokeColor = UIColor.black.cgColor
        //you can change the line width
        shapeLayer.lineWidth = 3.0
        view.layer.addSublayer(shapeLayer)
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        backgroundColor = UIColorFromRGB(rgbValue: 0x8385ed)
        infoText.fontSize = 48
        infoText.fontName = "PingFangTC-Light"
        infoText.verticalAlignmentMode = .top
        infoText.fontColor = UIColor.white
        infoText.position = CGPoint(x: frame.width / 2, y: frame.height * 0.9)
        
        arduinoTxt.fontSize = 36
        arduinoTxt.fontName = "PingFangTC-Light"
        arduinoTxt.verticalAlignmentMode = .top
        arduinoTxt.horizontalAlignmentMode = .center
        arduinoTxt.fontColor = UIColor.white
        arduinoTxt.position = CGPoint(x: frame.width / 2, y: frame.height * 0.4 - moveAnalogStick.radius - 20)
        addChild(infoText)
        addChild(arduinoTxt)
        addChild(moveAnalogStick)
    }
    
    func toOtherScene() {
        let newScene = JoystickScene()
        newScene.scaleMode = .resizeFill
        let transition = SKTransition.moveIn(with: SKTransitionDirection.right, duration: 1)
        view?.presentScene(newScene, transition: transition)
    }
    override func update(_ currentTime: TimeInterval) {
        /* Called before each frame is rendered */
    }
}
func UIColorFromRGB(rgbValue: UInt) -> UIColor {
    return UIColor(
        red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
        green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
        blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
        alpha: CGFloat(1.0)
    )
}
extension UIColor {
    func lighter(by percentage:CGFloat=30.0) -> UIColor? {
        return self.adjust(by: abs(percentage) )
    }
    
    func darker(by percentage:CGFloat=30.0) -> UIColor? {
        return self.adjust(by: -1 * abs(percentage) )
    }
    
    func adjust(by percentage:CGFloat=30.0) -> UIColor? {
        var r:CGFloat=0, g:CGFloat=0, b:CGFloat=0, a:CGFloat=0;
        if(self.getRed(&r, green: &g, blue: &b, alpha: &a)){
            return UIColor(red: min(r + percentage/100, 1.0),
                           green: min(g + percentage/100, 1.0),
                           blue: min(b + percentage/100, 1.0),
                           alpha: a)
        }else{
            return nil
        }
    }
}

