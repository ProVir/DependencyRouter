//
//  SecondViewController.swift
//  Example
//
//  Created by Короткий Виталий on 09.09.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import UIKit
import DependencyRouter

struct SecondViewControllerFactory: FactoryRouter, CreatorFactoryRouter, BlankFactoryRouter {
    let container: EmptyContainer
    
    func createViewController() -> SecondViewController {
        return createViewController(storyboardName: "Main", identifier: "second")
    }
    
    func setupViewController(_ viewController: SecondViewController) {
        viewController.data = "setuped"
        viewController.setupedByRouter = true
    }
}

class SecondViewController: UIViewController, AutoRouterViewController {
    typealias Factory = SecondViewControllerFactory
    var setupedByRouter = false
    
    var data = ""

    override func viewDidLoad() {
        data = "setuped from builder"
        Router.viewDidLoad(self)
        super.viewDidLoad()

        print("Second Data = \(data)")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }
    
    @IBAction func actionNext() {
        
        
    }
    
    
    @IBAction func actionModal() {
        
        
    }
    
}
