//
//  ViewController.swift
//  Test
//
//  Created by Ben Mechen on 12/11/2019.
//  Copyright © 2019 Ben Mechen. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var version: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        version.text = "Version " + (appVersion ?? "") + " Build " + (buildNumber ?? "")
    }


}

