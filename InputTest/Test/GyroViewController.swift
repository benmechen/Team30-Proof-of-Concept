//
//  GyroViewController.swift
//  Test
//
//  Created by Ben Mechen on 13/11/2019.
//  Copyright © 2019 Ben Mechen. All rights reserved.
//

import UIKit
import CoreMotion

class GyroViewController: UIViewController {

    var motionManager: CMMotionManager!
    @IBOutlet weak var box: UIView!
    @IBOutlet weak var directionImageView: UIImageView!
    @IBOutlet weak var sensitivity: UISlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        box.layer.cornerRadius = box.frame.height / 2
        directionImageView.tintColor = UIColor(named: "systemPinkColor")
        sensitivity.minimumValue = 0
        sensitivity.maximumValue = 1

        // Do any additional setup after loading the view.
        motionManager = CMMotionManager()
//        motionManager.startAccelerometerUpdates()
        
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.01
            motionManager.startDeviceMotionUpdates(to: .main) {
                [weak self] (data, error) in

                guard let data = data, error == nil else {
                    return
                }
                
                // Only change if signitificant input
                guard abs(data.rotationRate.x) >= 1 || abs(data.rotationRate.y) >= 1 else {
//                    self!.box.center = CGPoint(x: self!.view.center.x, y: self!.view.center.y)
                    return
                }
                
                
                if abs(data.attitude.roll) > abs(data.attitude.pitch) {
                    // X Axis
                    // Reverse sensitivty to UI input
                    if data.attitude.roll >= Double(1 - self!.sensitivity.value) {
                        self!.box.center = CGPoint(x: self!.view.center.x + 150, y: self!.view.center.y)
                        self!.directionImageView.image = UIImage(named: "left")
                    } else if data.attitude.roll <= Double(-(1 - self!.sensitivity.value)) {
                        self!.box.center = CGPoint(x: self!.view.center.x - 150, y: self!.view.center.y)
                        self!.directionImageView.image = UIImage(named: "right")
                    }
                } else {
                    // Y Axis
                    if data.attitude.pitch >= Double(1 - self!.sensitivity.value) {
                        self!.box.center = CGPoint(x: self!.view.center.x, y: self!.view.center.y + 300)
                        self!.directionImageView.image = UIImage(named: "up")
                    } else if data.attitude.pitch <= Double(-(1 - self!.sensitivity.value)) {
                        self!.box.center = CGPoint(x: self!.view.center.x, y: self!.view.center.y - 300)
                        self!.directionImageView.image = UIImage(named: "down")
                    }
                }
                
                
//                let rotation = atan2(data.gravity.x,
//                                     data.gravity.y) - .pi
            }
        }

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        motionManager.stopDeviceMotionUpdates()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func close(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
