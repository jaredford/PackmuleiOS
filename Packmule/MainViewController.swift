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
final class MainViewController: UIViewController, BluetoothSerialDelegate {
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var hornButton: UIButton!
    @IBOutlet weak var connectButton: UIBarButtonItem!
    var scene: GameScene!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Define the menus
        let menuLeftNavigationController = storyboard!.instantiateViewController(withIdentifier: "leftNavController") as! UISideMenuNavigationController
        menuLeftNavigationController.leftSide = true
        SideMenuManager.menuLeftNavigationController = menuLeftNavigationController
        SideMenuManager.menuAddPanGestureToPresent(toView: self.navBar)
        SideMenuManager.menuAddScreenEdgePanGesturesToPresent(toView: self.view, forMenu: UIRectEdge.left)
        SideMenuManager.menuPresentMode = .viewSlideInOut
        // Setup the joystick
        scene = GameScene(size: self.view.bounds.size)
        if let skView = self.view as? SKView {
            
            skView.showsFPS = false
            skView.showsNodeCount = false
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = true
            /* Set the scale mode to scale to fit the window */
            //scene.scaleMode = .AspectFill
            skView.presentScene(scene)
        }
        // init serial
        serial = BluetoothSerial(delegate: self)
        serial.writeType = .withoutResponse
    }
        override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    @IBAction func hornPress(_ sender: UIButton) {
        serial.sendMessageToDevice("h\n")
    }
    @IBAction func hamburgerPress(_ sender: UIBarButtonItem) {
            present(SideMenuManager.menuLeftNavigationController!, animated: true, completion: nil)
    }
    func reloadView() {
        // in case we're the visible view again
        navBar.barStyle = .black
        let color  = UIColor(colorLiteralRed: 0.12, green: 0.25, blue: 0.30, alpha: 1)
        navBar.barTintColor = color
            serial.delegate = self
        if serial.isReady {
            connectButton.title = "Disconnect"
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
            scene.arduinoTxt.text = "Bluetooth off"
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
            Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(MainViewController.scanTimeOut), userInfo: nil, repeats: false)
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
    /// Should be called 10s after we've begun scanning
    func scanTimeOut() {
        reloadView()
        scene.arduinoTxt.text = ""
        serial.stopScan()
    }
}