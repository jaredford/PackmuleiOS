//
//  RootNavController.swift
//  Packmule
//
//  Created by Jared Ford on 3/18/17.
//  Copyright © 2017 Bossman Solutions. All rights reserved.
//

import Foundation
import UIKit

class RootNavController : UITableViewController, UIPopoverPresentationControllerDelegate {
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var manualSwitch: UISwitch!
    @IBOutlet weak var navBar: UINavigationItem!
    @IBOutlet weak var speedSlider: UISlider!
    @IBOutlet weak var nameLabel: UILabel!
    let nameDialog = UIAlertController(title: "Name Your Packmule", message: "Enter a name", preferredStyle: UIAlertControllerStyle.alert)

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.barStyle = .black
        let color  = UIColor(colorLiteralRed: 0.05, green: 0.10, blue: 0.15, alpha: 1)
        self.navigationController?.navigationBar.barTintColor = color
        nameDialog.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        nameDialog.addAction(UIAlertAction(title: "Save", style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in UserDefaults.standard.set(self.nameDialog.textFields?[0].text, forKey: "packmule_name")
        self.nameLabel.text = self.nameDialog.textFields?[0].text}))
        nameDialog.addTextField(configurationHandler: {(textField: UITextField!) in
            textField.placeholder = "Enter Name"
            textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
            textField.text = (UserDefaults.standard.value(forKey: "packmule_name") ?? "Packmule") as? String
        })
        nameLabel.text = (UserDefaults.standard.value(forKey: "packmule_name") ?? "Packmule") as? String
        speedSlider.value = UserDefaults.standard.value(forKey: "max_speed") as! Float? ?? 50
        speedSlider.addTarget(self, action: #selector(sliderMoved(sliderState:)), for: UIControlEvents.valueChanged)
        sliderMoved(sliderState: speedSlider)
        manualSwitch.addTarget(self, action: #selector(stateChanged(switchState:)), for: UIControlEvents.valueChanged)
    }
    func stateChanged(switchState: UISwitch) {
       _ = MainViewController.sendMessage(message: switchState.isOn ? "m\n" : "a\n")
        UserDefaults.standard.set(switchState.isOn, forKey: "manual_mode")
        let nc = NotificationCenter.default
        nc.post(name:Notification.Name(rawValue:"ModeChanged"),
                object: nil,
                userInfo: ["manual":switchState.isOn])
    }
    func sliderMoved(sliderState: UISlider) {
        UserDefaults.standard.set(Int(ceil(sliderState.value)), forKey: "max_speed")
        speedLabel.text = "Max Speed: \(Int(ceil(sliderState.value)))%"
    }
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let view = UIView()
        view.backgroundColor = UIColor(colorLiteralRed: 0.05, green: 0.10, blue: 0.15, alpha: 1)
        cell.selectedBackgroundView = view
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch(indexPath.row) {            
        case 0:
            present(nameDialog, animated: true, completion: nil)
            break;
        case 1:
            manualSwitch.setOn(!manualSwitch.isOn, animated: true)
            stateChanged(switchState: manualSwitch)
            break;
        default:
            break;
        }
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
}
