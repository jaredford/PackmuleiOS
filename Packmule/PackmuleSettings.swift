//
//  PackmuleSettings.swift
//  Packmule
//
//  Created by Jared Ford on 3/18/17.
//  Copyright © 2017 Bossman Solutions. All rights reserved.
//

import Foundation
import UIKit
import Darwin

class PackmuleSettings{
    class func PackmuleSetting(){
        UserDefaults.standard.setValue("hello", forKey: "world")
        print(UserDefaults.standard.value(forKey: "world") ?? "error")
    }
}
