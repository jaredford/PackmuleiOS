import SpriteKit
import UIKit
import CoreBluetooth
class JoystickScene: SKScene {
    
    let moveAnalogStick = AnalogJoystick(diameters: (300,50), colors: (UIColorFromRGB(rgbValue : 0xf2b807), UIColorFromRGB(rgbValue : 0xf40077)))
    //let moveAnalogStick = AnalogJoystick(diameters: (300,100), images: (UIImage(named: "image_button_bg"), UIImage(named: "image_button")))
    let arduinoTxt = SKLabelNode(text: "")
    let infoText = SKLabelNode(text: "")
    override func didMove(to view: SKView) {
        /* Setup your scene here */
        //MARK: Handlers begin
        addLabels(view: view)
        moveAnalogStick.trackingHandler = {[unowned self] data in
            if(UserDefaults.standard.bool(forKey: "manual_mode")) {
            self.infoText.text = data.description
            _ = MainViewController.sendMessage(message: "\(data.sendingMessage)\n")
            }
        }
        
        moveAnalogStick.stopHandler = {
            if(UserDefaults.standard.bool(forKey: "manual_mode")){
            self.infoText.text = "Stopped"
            _ = MainViewController.sendMessage(message: "127127\n")
            }else {
            self.infoText.text = "Following"
            }
        }
        
        //MARK: Handlers end
        
        view.isMultipleTouchEnabled = true
    }
    
    func addLabels (view: SKView) {
        moveAnalogStick.position = CGPoint(x: frame.width / 2, y: frame.height * 0.4)
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: frame.width / 2, y: (frame.height * 0.6)), radius: CGFloat(150), startAngle: CGFloat(0), endAngle:CGFloat(M_PI * 2), clockwise: true)
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = circlePath.cgPath
        
        //change the fill color
        shapeLayer.fillColor = UIColor.clear.cgColor
        //you can change the stroke color
        shapeLayer.strokeColor = UIColor.black.cgColor
        //you can change the line width
        shapeLayer.lineWidth = 3.0
        
        view.layer.addSublayer(shapeLayer)
        backgroundColor = UIColor.lightGray
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        infoText.fontSize = 48
        infoText.fontName = "PingFangTC-Light"
        infoText.verticalAlignmentMode = .top
        infoText.fontColor = UIColor.black
        infoText.position = CGPoint(x: frame.width / 2, y: frame.height * 0.9)
        
        arduinoTxt.fontSize = 36
        arduinoTxt.fontName = "PingFangTC-Light"
        arduinoTxt.verticalAlignmentMode = .top
        arduinoTxt.horizontalAlignmentMode = .center
        arduinoTxt.fontColor = UIColor.black
        arduinoTxt.position = CGPoint(x: frame.width / 2, y: frame.height * 0.4 - moveAnalogStick.radius - 20)
        addChild(self.infoText)
        addChild(self.arduinoTxt)
        addChild(moveAnalogStick)
    }
    func toOtherScene() {
        let newScene = JoystickScene()
        newScene.scaleMode = .resizeFill
        let transition = SKTransition.moveIn(with: SKTransitionDirection.right, duration: 1)
        view?.presentScene(newScene, transition: transition)
    }
    
    func setRandomStickColor() {
        
        let randomColor = UIColor.random()
        moveAnalogStick.stick.color = randomColor
    }
    
    func setRandomSubstrateColor() {
        
        let randomColor = UIColor.random()
        moveAnalogStick.substrate.color = randomColor
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
    
    static func random() -> UIColor {
        
        return UIColor(red: CGFloat(drand48()), green: CGFloat(drand48()), blue: CGFloat(drand48()), alpha: 1)
    }
}
