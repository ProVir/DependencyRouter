//
//  SecondViewController.swift
//  Example
//
//  Created by Короткий Виталий on 09.09.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import UIKit
import DependencyRouter

struct SecondViewControllerFactory: AutoFactoryRouter, CreatorFactoryRouter, BlankFactoryRouter {
    let container: Container
    struct Container: AutoServiceContainer {
        
    }
    
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
        Router.prepare(for: segue, sender: sender, source: nil)
    }
    
    @IBAction func actionNext() {
        BuilderRouter(SecondViewControllerFactory.self).createAndSetup().present(on: self)
    }
    
    
    @IBAction func actionModal() {
        BuilderRouter(ModalViewControllerFactory.self).createAndSetup(params: .init(message: "Hello!"), callback:
            { print("Closed modal with message: \($0)") }).present(on: self)
    }
    
}

extension SecondViewController: ModalViewControllerCallback {
    func closedModal() {
        print("Closed last modal")
    }
}
