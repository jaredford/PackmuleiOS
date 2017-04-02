import SpriteKit
import Foundation
//MARK: AnalogJoystickData
public struct AnalogJoystickData: CustomStringConvertible {
    
    var velocity = CGPoint.zero,
    angular = CGFloat(0)
    
    mutating func reset() {
        velocity = CGPoint.zero
        angular = 0
    }
    
    public var description: String {
        let angle = Double(angular)
        if(angle > -.pi/4 / 2.0 && angle < .pi/4 / 2.0){
            return "Forward"
        }
        if(angle >= .pi/4 / 2.0 && angle < 3.0 / 2.0 * .pi/4){
            return "Forward Left"
        }
        if(angle >= 3.0 / 2.0 * .pi/4 && angle <  5.0 / 2.0 * .pi/4){
            return "Left"
        }
        if(angle >= 5.0 / 2.0 * .pi/4 && angle <  7.0 / 2.0 * .pi/4){
            return "Reverse Left"
        }
        if(angle <= -.pi/4 / 2.0 && angle >  -3.0 / 2.0 * .pi/4){
            return "Forward Right"
        }
        if(angle <= -3.0 / 2.0 * .pi/4 && angle >  -5.0 / 2.0 * .pi/4){
            return "Right"
        }
        if(angle <= -5.0 / 2.0 * .pi/4 && angle >  -7.0 / 2.0 * .pi/4){
            return "Reverse Right"
        }
        return "Reverse"
    }
    
    public var sendingMessage: String {
        let scalingFactor = (UserDefaults.standard.value(forKey: "max_speed") as! Double? ?? 50) / 100
        var speed = Double(sqrt(pow(velocity.x,2) + pow(velocity.y,2)))
        speed = velocity.y > 0 ? speed : -1 * speed
        speed = speed * scalingFactor * 127 / 150 + 127
        var direction = Double(velocity.x)
        direction = direction * scalingFactor * 127 / 150 + 127
        return String(format: "%03d%03d", Int(ceil(speed)), Int(ceil(direction)))
    }
}

//MARK: - AnalogJoystickComponent
open class AnalogJoystickComponent: SKSpriteNode {
    
    private var kvoContext = UInt8(1)
    var borderWidth = CGFloat(0) { didSet { redrawTexture() } }
    var borderColor = UIColor.black { didSet { redrawTexture() } }
    var image: UIImage? { didSet { redrawTexture() } }
    
    var diameter: CGFloat {
        get { return max(size.width, size.height) }
        set { size = CGSize(width: newValue, height: newValue) }
    }
    
    var radius: CGFloat {
        
        get { return diameter / 2 }
        set { diameter = newValue * 2 }
    }
    
    init(diameter: CGFloat, color: UIColor? = nil, image: UIImage? = nil) { // designated
        
        super.init(texture: nil, color: color ?? UIColor.black, size: CGSize(width: diameter, height: diameter))
        
        addObserver(self, forKeyPath: "color", options: NSKeyValueObservingOptions.old, context: &kvoContext) // listen color changes
        
        
        self.diameter = diameter
        self.image = image
        redrawTexture()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        removeObserver(self, forKeyPath: "color")
    }
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        redrawTexture()
    }
    
    private func redrawTexture() {
        
        guard diameter > 0 else {
            texture = nil
            print("Diameter should be more than zero")
            return
        }
        
        let scale = UIScreen.main.scale,
        needSize = CGSize(width: self.diameter, height: self.diameter)
        UIGraphicsBeginImageContextWithOptions(needSize, false, scale)
        let rectPath = UIBezierPath(ovalIn: CGRect(origin: CGPoint.zero, size: needSize))
        rectPath.addClip()
        
        color.set()
        rectPath.fill()
        
        if let img = image {
            img.draw(in: CGRect(origin: CGPoint.zero, size: needSize), blendMode: .normal, alpha: 1)
        }
        
        let needImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        texture = SKTexture(image: needImage)
    }
}

//MARK: - AnalogJoystickSubstrate
open class AnalogJoystickSubstrate: AnalogJoystickComponent {
    
    // coming soon...
}

//MARK: - AnalogJoystickStick
open class AnalogJoystickStick: AnalogJoystickComponent {
    
    // coming soon...
}

//MARK: - AnalogJoystick
typealias 🕹 = AnalogJoystick
open class AnalogJoystick: SKNode {
    
    var trackingHandler: ((AnalogJoystickData) -> ())?,
    startHandler: (() -> Void)?,
    stopHandler: (() -> Void)?,
    substrate: AnalogJoystickSubstrate!,
    stick: AnalogJoystickStick!
    private var tracking = false
    private(set) var data = AnalogJoystickData()
    
    var disabled: Bool {
        get { return !isUserInteractionEnabled }
        set {
            isUserInteractionEnabled = !newValue
            if newValue {
                resetStick()
            }
        }
    }
    
    var diameter: CGFloat {
        get { return substrate.diameter }
        set {
            stick.diameter += newValue - diameter
            substrate.diameter = newValue
        }
    }
    
    var radius: CGFloat {
        get { return diameter / 2 }
        set { diameter = newValue * 2 }
    }
    
    init(substrate: AnalogJoystickSubstrate, stick: AnalogJoystickStick) {
        super.init()
        
        self.substrate = substrate
        substrate.zPosition = 0
        addChild(substrate)
        
        self.stick = stick
        self.stick.alpha = 0
        stick.zPosition = substrate.zPosition + 1
        addChild(stick)
        
        disabled = false
        let velocityLoop = CADisplayLink(target: self, selector: #selector(listen))
        velocityLoop.add(to: RunLoop.current, forMode: RunLoopMode(rawValue: RunLoopMode.commonModes.rawValue))
    }
    
    convenience init(diameters: (substrate: CGFloat, stick: CGFloat?), colors: (substrate: UIColor?, stick: UIColor?)? = nil, images: (substrate: UIImage?, stick: UIImage?)? = nil) {
        let stickDiameter = diameters.stick ?? diameters.substrate * 0.6,
        jColors = colors ?? (substrate: nil, stick: nil),
        jImages = images ?? (substrate: nil, stick: nil),
        substrate = AnalogJoystickSubstrate(diameter: diameters.substrate, color: jColors.substrate, image: jImages.substrate),
        stick = AnalogJoystickStick(diameter: stickDiameter, color: jColors.stick, image: jImages.stick)
        self.init(substrate: substrate, stick: stick)
    }
    
    convenience init(diameter: CGFloat, colors: (substrate: UIColor?, stick: UIColor?)? = nil, images: (substrate: UIImage?, stick: UIImage?)? = nil) {
        self.init(diameters: (substrate: diameter, stick: nil), colors: colors, images: images)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func listen() {
        if tracking {
            trackingHandler?(data)
        }
    }
    
    //MARK: - Overrides
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if let touch = touches.first, substrate == atPoint(touch.location(in: self)) {
            let location = touch.location(in: self)
            stick.alpha = 0.8;
            let maxDistantion = substrate.radius,
            realDistantion = sqrt(pow(location.x, 2) + pow(location.y, 2)),
            needPosition = realDistantion <= maxDistantion ? CGPoint(x: location.x, y: location.y) : CGPoint(x: location.x / realDistantion * maxDistantion, y: location.y / realDistantion * maxDistantion)
            stick.position = needPosition
            data = AnalogJoystickData(velocity: needPosition, angular: -atan2(needPosition.x, needPosition.y))
            tracking = true
            startHandler?()
        }
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for touch: AnyObject in touches {
            let location = touch.location(in: self)
            
            guard tracking else {
                return
            }
            
            let maxDistantion = substrate.radius,
            realDistantion = sqrt(pow(location.x, 2) + pow(location.y, 2)),
            needPosition = realDistantion <= maxDistantion ? CGPoint(x: location.x, y: location.y) : CGPoint(x: location.x / realDistantion * maxDistantion, y: location.y / realDistantion * maxDistantion)
            stick.position = needPosition
            data = AnalogJoystickData(velocity: needPosition, angular: -atan2(needPosition.x, needPosition.y))
        }
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetStick()
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetStick()
    }
    
    // CustomStringConvertible protocol
    open override var description: String {
        return "AnalogJoystick(data: \(data), position: \(position))"
    }
    
    // private methods
    private func resetStick() {
        tracking = false
        let moveToBack = SKAction.move(to: CGPoint.zero, duration: TimeInterval(0.1))
        moveToBack.timingMode = .easeOut
        stick.run(moveToBack)
        stick.alpha = 0
        data.reset()
        stopHandler?();
    }
}
