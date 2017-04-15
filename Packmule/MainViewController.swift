import UIKit
import SpriteKit
import CoreBluetooth
import QuartzCore
import SideMenu
/// The option to add a \n or \r or \r\n to the end of the send message
enum MessageOption: Int {
    case noLineEnding,
    newline,
    carriageReturn,
    carriageReturnAndNewline
}

/// The option to add a \n to the end of the received message (to make it more readable)
enum ReceivedMessageOption: Int {
    case none,
    newline
}
final class MainViewController: UIViewController,BluetoothSerialDelegate {
    @IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet weak var hornButton: UIButton!
    @IBOutlet weak var connectButton: UIBarButtonItem!
    let myNotification = Notification.Name(rawValue:"ModeChanged")
    var scene: JoystickScene!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup notification listener
        let nc = NotificationCenter.default
        nc.addObserver(forName:myNotification, object:nil, queue:nil, using:catchNotification)
        // Define the menus
        SideMenuManager.menuEnableSwipeGestures = false
        let menuLeftNavigationController = storyboard!.instantiateViewController(withIdentifier: "leftNavController") as! UISideMenuNavigationController
        menuLeftNavigationController.leftSide = true
        SideMenuManager.menuLeftNavigationController = menuLeftNavigationController
        SideMenuManager.menuAddPanGestureToPresent(toView: (self.navigationController?.navigationBar)!)
        SideMenuManager.menuAddScreenEdgePanGesturesToPresent(toView: self.view, forMenu: UIRectEdge.left)
        SideMenuManager.menuPresentMode = .viewSlideInOut
        SideMenuManager.menuWidth = UIScreen.main.bounds.width * 0.83
        
        // Style the navigation bar
        let view = UIView()
        view.backgroundColor = UIColor.white
        self.navigationController?.navigationBar.barStyle = .black
        self.navigationController?.navigationBar.barTintColor = UIColorFromRGB(rgbValue: 0x3b58c7).darker(by: 20)
        connectButton.tintColor = UIColor.white
        menuButton.tintColor = UIColor.white	
        //let color  = UIColor(colorLiteralRed: 0.05, green: 0.10, blue: 0.15, alpha: 1)
        //self.navigationController?.navigationBar.barTintColor = color
        
        // Setup the joystick
        scene = JoystickScene(size: self.view.bounds.size)
        if let skView = self.view as? SKView {
            
            skView.showsFPS = false
            skView.showsNodeCount = false
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = true
            /* Set the scale mode to scale to fit the window */
            //scene.scaleMode = .AspectFill
            skView.presentScene(scene)
            UserDefaults.standard.set(true, forKey: "manual_mode")
            scene.infoText.text = "Stopped"
        }
        // init serial
        serial = BluetoothSerial(delegate: self)
        serial.writeType = .withoutResponse
    }
        override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    func catchNotification(notification:Notification) -> Void {
        guard let userInfo = notification.userInfo,
            let manual  = userInfo["manual"] as? Bool
            else {
                print("No userInfo found in notification")
                return
        }
        if manual{
            scene.infoText.text = "Stopped"
            scene.moveAnalogStick.substrate.color = UIColorFromRGB(rgbValue : 0xf2b807)
        }
        else{
            scene.infoText.text = "Following"
            scene.engagedEStop = false
            scene.moveAnalogStick.substrate.color = UIColor.green.darker(by: 20)!
        }
    }
    override var prefersStatusBarHidden : Bool {
        return true
    }
    @IBAction func hornPress(_ sender: UIButton) {
        serial.sendMessageToDevice("h\n")
    }
    @IBAction func hamburgerPress(_ sender: UIBarButtonItem) {present(SideMenuManager.menuLeftNavigationController!, animated: true, completion: nil)
    }
    func reloadView() {
        // in case we're the visible view again
            serial.delegate = self
        if serial.isReady {
            connectButton.title = "Disconnect"
            syncManualMode()
            hornButton.isEnabled = true
            connectButton.isEnabled = true
        } else if serial.centralManager.state == .poweredOn {
            connectButton.title = "Connect"
            connectButton.isEnabled = true
            hornButton.isEnabled = false
        } else {
            connectButton.title = "Connect"
            hornButton.isEnabled = false
            connectButton.isEnabled = false
        }
    }
    func syncManualMode() {
        _ = MainViewController.sendMessage(message: UserDefaults.standard.bool(forKey: "manual_mode") ? "m\n" : "a\n")
    }
    //MARK: BluetoothSerialDelegate
    
    func serialDidReceiveString(_ message: String) {
        scene.arduinoTxt.text = message
    }
    func serialDidConnect(_ peripheral: CBPeripheral) {
        connectButton.title = "Disconnect"
        hornButton.isEnabled = true
    }
    
    func serialDidDisconnect(_ peripheral: CBPeripheral, error: NSError?) {
        reloadView()
    }
    
    func serialDidChangeState() {
        reloadView()
        if serial.centralManager.state != .poweredOn {
            //scene.arduinoTxt.text = "Bluetooth off"
            hornButton.imageView?.alpha = 0
        }
        else {
            hornButton.imageView?.alpha = 1
            scene.arduinoTxt.text = ""
        }
    }
    func serialDidDiscoverPeripheral(_ peripheral: CBPeripheral, RSSI: NSNumber?) {
        // check whether it is a duplicate
        if(peripheral.name == "Packmule"){
            scanTimeOut()
            serial.connectToPeripheral(peripheral)
            reloadView()
        }
    }
    func serialDidFailToConnect(_ peripheral: CBPeripheral, error: NSError?) {
        scene.arduinoTxt.text = "Failed to connect"
    }
    
    @IBAction func connectPressed(_ sender: UIBarButtonItem) {
        // Similarly, to dismiss a menu programmatically, you would do this:
        dismiss(animated: true, completion: nil)
        if serial.connectedPeripheral == nil {
            // start scanning and schedule the time out
            serial.startScan()
            connectButton.title = "Scanning..."
            connectButton.isEnabled = false
            Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(MainViewController.scanTimeOut), userInfo: nil, repeats: false)
        } else {
            serial.disconnect()
            reloadView()
        }

    }
    class func sendMessage(message: String) -> Bool{
        if !serial.isReady {
            return true
        }
        // send the message and clear the textfield
        serial.sendMessageToDevice(message)
        return true
    }
    /// Should be called 5s after we've begun scanning
    func scanTimeOut() {
        reloadView()
        scene.arduinoTxt.text = ""
        serial.stopScan()
    }
}
