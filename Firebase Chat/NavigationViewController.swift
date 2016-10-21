//
//  NavigationViewController.swift
//  Firebase Chat
//
//  Created by Ali Akkawi on 10/18/16.
//  Copyright © 2016 Ali Akkawi. All rights reserved.
//

import UIKit

class NavigationViewController: UINavigationController {

    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        
        // color of TITLE.
        
        self.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        
        // COLOR OF THE BUTTONS.
        
        self.navigationBar.tintColor = UIColor.white
        
        // color of the background of the navigation controller.
        
        self.navigationBar.barTintColor = UIColor(red: 18.0/255.0, green: 86.0/255.0, blue: 136.0/255.0, alpha: 1)
        
        // unable translucent
        
        self.navigationBar.isTranslucent = false
        
        
       
    }

    
}
