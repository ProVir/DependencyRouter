//
//  ViewController.swift
//  Example
//
//  Created by Короткий Виталий on 08.09.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import UIKit
import DependencyRouter

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }

    @IBAction func actionNext() {
//        let presenter = BuilderRouter(SecondViewControllerFactory.self).setContainer(Void()).create().setup()
//        BuilderRouter(SecondViewControllerFactory.self).createAndSetup().present(NavigationControllerPresentationRouter(), on: self)
        
        BuilderRouter(SecondViewControllerFactory.self).createAndSetup()
            .prepareHandler { print("Prepare open") }
            .postHandler { print("Post open") }
            .present(on: self)
    }
    
}

