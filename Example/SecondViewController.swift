//
//  SecondViewController.swift
//  Example
//
//  Created by Короткий Виталий on 09.09.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import UIKit
import DependencyRouter

struct SecondViewControllerFactory: LightFactoryRouter, CreatorFactoryRouter, BlankFactoryRouter {
    func createViewController() -> SecondViewController {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        return sb.instantiateViewController(withIdentifier: "second") as! SecondViewController
    }
    
    func setupViewController(_ viewController: SecondViewController) {
        viewController.data = "setuped"
    }
}

class SecondViewController: UIViewController {
    
    var data = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        print("Second Data = \(data)")
    }
    
    
    @IBAction func actionNext() {
        
        
    }
    
    
    @IBAction func actionModal() {
        
        
    }
    
}
