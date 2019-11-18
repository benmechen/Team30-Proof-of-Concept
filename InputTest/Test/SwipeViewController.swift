//
//  SwipeViewController.swift
//  Test
//
//  Created by Ben Mechen on 12/11/2019.
//  Copyright © 2019 Ben Mechen. All rights reserved.
//

import UIKit

class SwipeViewController: UIViewController {

    @IBOutlet weak var box: UIView!
    @IBOutlet weak var directionImageView: UIImageView!
    @IBOutlet weak var lockControlSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        box.layer.cornerRadius = box.frame.height / 2
    }
    
    
    @IBAction func handlePan(recognizer: UIPanGestureRecognizer) {
        // Get direction from velocity: Left, Right, Up, Down
        
        let translation = recognizer.translation(in: self.view)
        let velocity = recognizer.velocity(in: view)
        
        switch lockControlSwitch.isOn {
        case false:
            // Unlock control
            var x = translation.x
            if (box.center.x + translation.x) > view.center.x + 150 {
                // Right
                x = box.center.x - (view.center.x + 150)
            } else if (box.center.x + translation.x) < view.center.x - 150 {
                // Left
                x = (view.center.x - 150) - box.center.x
            }
            
            var y = translation.y
            if (box.center.y + translation.y) > view.center.y + 300 {
                // Up
                y = box.center.y - (view.center.y + 300)
            } else if (box.center.y + translation.y) < view.center.y - 300 {
                // Down
                y = (view.center.y - 300) - box.center.y
            }
            
            if abs(velocity.x) > abs(velocity.y) {
                if velocity.x > 0 {
                    directionImageView.image = UIImage(named: "right")
                } else {
                    directionImageView.image = UIImage(named: "left")
                }
            } else {
                if velocity.y > 0 {
                    directionImageView.image = UIImage(named: "down")
                } else {
                    directionImageView.image = UIImage(named: "up")
                }
            }
            
            box.center = CGPoint(x: box.center.x + x, y: box.center.y + y)
        default:
            if abs(velocity.x) > abs(velocity.y) {
                // Horizontal
                print("Horizontal")
                var x = translation.x
                if (box.center.x + translation.x) > view.center.x + 150 {
                    // Right
                    x = box.center.x - (view.center.x + 150)
                } else if (box.center.x + translation.x) < view.center.x - 150 {
                    // Left
                    x = (view.center.x - 150) - box.center.x
                }
                
                if velocity.x > 0 {
                    directionImageView.image = UIImage(named: "right")
                } else {
                    directionImageView.image = UIImage(named: "left")
                }
                
                directionImageView.tintColor = UIColor(named: "systemPinkColor")
                
                box.center = CGPoint(x: box.center.x + x, y: box.center.y)
            } else {
                // Vertical
                print("Vertical")
                var y = translation.y
                if (box.center.y + translation.y) > view.center.y + 300 {
                    // Up
                    y = box.center.y - (view.center.y + 300)
                } else if (box.center.y + translation.y) < view.center.y - 300 {
                    // Down
                    y = (view.center.y - 300) - box.center.y
                }
                
                if velocity.y > 0 {
                    directionImageView.image = UIImage(named: "down")
                } else {
                    directionImageView.image = UIImage(named: "up")
                }
                
                directionImageView.tintColor = UIColor(named: "systemPinkColor")
                
                box.center = CGPoint(x: box.center.x, y: box.center.y + y)
            }
        }
        
        recognizer.setTranslation(CGPoint.zero, in: self.view)
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
