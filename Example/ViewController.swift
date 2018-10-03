//
//  ViewController.swift
//  Example
//
//  Created by Короткий Виталий on 08.09.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import UIKit
import DependencyRouter

struct ViewControllerFactory: LightFactoryRouter, BlankFactoryRouter {
    func setupViewController(_ viewController: ViewController) {
        viewController.router = ViewControllerRouter(viewController)
    }
}

class ViewControllerRouter: NavigationRouter<ViewController> {
    func presentNext() {
        simplePresent(SecondViewControllerFactory.self)
//        performSegue(withIdentifier: "next", factory: SecondViewControllerFactory())
    }
    
    func presentThird() {
        BuilderRouter(ThirdViewControllerFactory.self).createAndSetup().present(on: self.viewController)
    }
}

class ViewController: UIViewController, AutoRouterViewController {
    typealias Factory = ViewControllerFactory
    var setupedByRouter: Bool { return router != nil }
    
    var router: ViewControllerRouter!
    
    override func viewDidLoad() {
        Router.viewDidLoad(self)
        super.viewDidLoad()
        
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        router.prepare(for: segue, sender: sender)
    }

    @IBAction func actionNext() {
        router.presentNext()
    }
    
    @IBAction func actionThird() {
        router.presentThird()
    }
    
    
    @IBAction func unwindCancel(_ segue: UIStoryboardSegue) {
        router.unwindSegue(segue)
    }
}

extension ViewController: CallbackUnwindInputSource {
    func callbackForUnwindRouter(_ unwindType: CoreUnwindCallbackRouter.Type, segueIdentifier: String?) -> Any? {
        if unwindType == ModalViewController.self {
            return ModalViewController.useCallback({ print("Message closed: \($0)") })
        }
        
        return nil
    }
}
