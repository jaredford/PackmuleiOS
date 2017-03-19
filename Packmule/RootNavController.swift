//
//  RootNavController.swift
//  Packmule
//
//  Created by Jared Ford on 3/18/17.
//  Copyright © 2017 Bossman Solutions. All rights reserved.
//

import Foundation
import UIKit

class RootNavController : UITableViewController {
    @IBOutlet weak var navBar: UINavigationItem!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.barStyle = .black
        let color  = UIColor(colorLiteralRed: 0.05, green: 0.10, blue: 0.15, alpha: 1)
        self.navigationController?.navigationBar.barTintColor = color
    }
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let view = UIView()
        view.backgroundColor = UIColor(colorLiteralRed: 0.05, green: 0.10, blue: 0.15, alpha: 1)
        cell.selectedBackgroundView = view
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        PackmuleSettings.PackmuleSetting()
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
}
