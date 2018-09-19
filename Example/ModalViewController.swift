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
    
    func defaultPresentation() -> PresentationRouter {
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

class ModalViewController: UIViewController, SourceRouterViewController, SelfUnwindRouterViewController {
    typealias Factory = ModalViewControllerFactory
    
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
        Router.prepare(for: segue, sender: sender, source: self)
    }
    
    @IBAction func actionClose() {
        navigationController?.dismiss(animated: true, completion: { [callback] in
            callback("Hello closed!")
        })
    }
    
    @IBAction func actionNext() {
        BuilderRouter(SecondViewControllerFactory.self).createAndSetup().present(on: self)
    }
    
    
    @IBAction func actionModal() {
        BuilderRouter(ModalViewControllerFactory.self).createAndSetup(source: self).present(on: self)
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