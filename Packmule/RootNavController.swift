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
        let color  = UIColor(colorLiteralRed: 0.12, green: 0.25, blue: 0.30, alpha: 1)
        self.navigationController?.navigationBar.barTintColor = color
    }
}
