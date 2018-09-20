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
        viewController.router = SecondViewControllerRouter(viewController)
        viewController.data = "setuped"
        viewController.setupedByRouter = true
    }
}

class SecondViewControllerRouter: VCNavigationRouter<SecondViewController>, ParamsFactoryInputSource, CallbackFactoryInputSource {
    func presentNext() {
        simplePresent(SecondViewControllerFactory.self)
    }
    
    func presentModal() {
//        BuilderRouter(ModalViewControllerFactory.self).createAndSetup(params: .init(message: "Hello!"), callback:{ print("Closed modal with message: \($0)") }).present(on: associatedViewController!)
//        simplePresent(ModalViewControllerFactory.self, params: .init(message: "Hello!"), callback:{ print("Closed modal with message: \($0)") })
        simplePresentUseSource(ModalViewControllerFactory.self)
    }
    
    
    func paramsForFactoryRouter(_ routerType: CoreFactoryRouter.Type, identifier: String?, sender: Any?) -> Any? {
        if routerType == ModalViewControllerFactory.self {
            return ModalViewControllerFactory.Params(message: viewController.data)
        }
        
        return nil
    }
    
    func callbackForFactoryRouter(_ routerType: CoreFactoryRouter.Type, identifier: String?, sender: Any?) -> Any? {
        if routerType == ModalViewControllerFactory.self {
            return ModalViewControllerFactory.useCallback({ print("Closed modal with message: \($0)") })
        }
        
        return nil
    }
}

class SecondViewController: UIViewController, AutoRouterViewController {
    typealias Factory = SecondViewControllerFactory
    var setupedByRouter = false
    
    var router: SecondViewControllerRouter!
    
    var data = ""

    override func viewDidLoad() {
        data = "setuped from builder"
        Router.viewDidLoad(self)
        super.viewDidLoad()

        print("Second Data = \(data)")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        router.prepare(for: segue, sender: sender)
    }
    
    @IBAction func actionNext() {
        router.presentNext()
    }
    
    
    @IBAction func actionModal() {
        router.presentModal()
    }
}

extension SecondViewController: ModalViewControllerCallback {
    func closedModal() {
        print("Closed last modal")
    }
}
