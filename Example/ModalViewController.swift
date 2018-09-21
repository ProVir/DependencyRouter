//
//  ModalViewController.swift
//  Example
//
//  Created by Короткий Виталий on 09.09.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import UIKit
import DependencyRouter

protocol ModalViewControllerCallback: class {
    func closedModal()
}

struct ModalViewControllerFactory: LightFactoryRouter, CreatorFactoryRouter, ParamsWithCallbackFactoryRouter {
    struct Params {
        let message: String
    }
    
    func presentation() -> PresentationRouter {
        return ModalPresentationRouter()
    }
    
    func createViewController() -> ModalViewController {
        return createViewController(storyboardName: "Main", identifier: "modalContent")
    }
    
    func setupViewController(_ viewController: ModalViewController, params: Params, callback: @escaping (String)->Void) {
        viewController.message = params.message
        viewController.callback = callback
    }
}

class ModalViewControllerRouter: BaseNavigationRouter {
    func presentNext() {
        BuilderRouter(SecondViewControllerFactory.self).createAndSetup().present(on: associatedViewController!)
    }
    
    func presentModal() {
        //        BuilderRouter(ModalViewControllerFactory.self).createAndSetup(params: .init(message: "Hello!"), callback:{ print("Closed modal with message: \($0)") }).present(on: associatedViewController!)
        simplePresentUseSource(ModalViewControllerFactory.self)
    }
}

class ModalViewController: UIViewController, SourceRouterViewController, SelfUnwindRouterViewController {
    typealias Factory = ModalViewControllerFactory
    private lazy var router = ModalViewControllerRouter(self)
    
    func unwindUseCallback(callback: @escaping (String)->Void, segueIdentifier: String?) {
        callback("used UNWIND with id = \(segueIdentifier ?? "")")
    }
    
    var message: String!
//    weak var callback: ModalViewControllerCallback?
    var callback: (String)->Void = { _ in }

    override func viewDidLoad() {
        super.viewDidLoad()

        print("Presented with Message: \(message!)")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        router.prepare(for: segue, sender: sender)
    }
    
    @IBAction func actionClose() {
        router.dismiss()
    }
    
    @IBAction func actionNext() {
        router.presentNext()
    }
    
    
    @IBAction func actionModal() {
        router.presentModal()
//        BuilderRouter(ModalViewControllerFactory.self).createAndSetup(source: self).present(on: self)
    }

}

extension ModalViewController: ParamsFactoryInputSource, CallbackFactoryInputSource {
    func paramsForFactoryRouter(_ routerType: CoreFactoryRouter.Type, identifier: String?, sender: Any?) -> Any? {
        if routerType == ModalViewControllerFactory.self {
            return ModalViewControllerFactory.Params(message: message)
        }
        
        return nil
    }
    
    func callbackForFactoryRouter(_ routerType: CoreFactoryRouter.Type, identifier: String?, sender: Any?) -> Any? {
        if routerType == ModalViewControllerFactory.self {
            return ModalViewControllerFactory.useCallback({ print("Modal: closed other modal, message = \($0)") })
        }
        
        return nil
    }
}

extension ModalViewController: ModalViewControllerCallback {
    func closedModal() {
        print("Modal: closed other modal")
    }
}
