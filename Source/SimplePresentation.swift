//
//  SimplePresentationRouter.swift
//  DependencyRouter
//
//  Created by Короткий Виталий on 11.09.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import UIKit


/// Assert if use - used as default when require always use own
public struct NotPresentationRouter: PresentationRouter {
    public init() { }
    
    public func present(_ viewController: UIViewController, on existingController: UIViewController, animated: Bool, completionHandler: @escaping (PresentationRouterResult) -> Void) {
        assertionFailure("You need use valid PresentationRouter, don't use NotPresentationRouter.")
        completionHandler(.failure(DependencyRouterError.notReadyPresentingViewController("need use valid PresentationRouter, don't use NotPresentationRouter.")))
    }
}

/// Show used UIViewController.show(_ vc: UIViewController, sender: Any?), as default
public struct ShowPresentationRouter: PresentationRouter {
    public var prepareHandler: ((UIViewController)->Void)? = nil
    public var postHandler: ((UIViewController)->Void)? = nil
    
    public init() { }
    
    public func present(_ viewController: UIViewController, on existingController: UIViewController, animated: Bool, completionHandler: @escaping (PresentationRouterResult) -> Void) {
        
        prepareHandler?(viewController)
        
        if !animated { UIView.setAnimationsEnabled(false) }
        existingController.show(viewController, sender: nil)
        if !animated { UIView.setAnimationsEnabled(true) }
        
        postHandler?(viewController)
        completionHandler(.success)
    }
}

/// Present ViewController as Modal
public struct ModalPresentationRouter: PresentationRouter {
    public var canAutoWrappedNavigtionController: Bool = true
    public var canDismissOtherPresented: Bool = false
    
    public var prepareHandler: ((UIViewController)->Void)? = nil
    public var postHandler: ((UIViewController)->Void)? = nil
    
    public init(autoWrapped: Bool = true, dismissOtherPresented: Bool = false, prepareHandler: ((UIViewController)->Void)? = nil) {
        self.canAutoWrappedNavigtionController = autoWrapped
        self.canDismissOtherPresented = dismissOtherPresented
        self.prepareHandler = prepareHandler
    }
    
    public func present(_ viewController: UIViewController, on existingController: UIViewController, animated: Bool, completionHandler: @escaping (PresentationRouterResult) -> Void) {
        //1. Test - can presented
        guard !canDismissOtherPresented, existingController.presentedViewController == nil else {
            completionHandler(.failure(DependencyRouterError.notReadyPresentingViewController("is already presenting a view controller")))
            return
        }
        
        //2. Prepare
        let presentViewController: UIViewController
        if canAutoWrappedNavigtionController && !(viewController is UINavigationController) {
            presentViewController = UINavigationController(rootViewController: viewController)
        } else {
            presentViewController = viewController
        }
        
        prepareHandler?(viewController)
        
        //3. Present
        let postHandler = self.postHandler
        func present() {
            existingController.present(presentViewController, animated: animated) {
                postHandler?(viewController)
                completionHandler(.success)
            }
        }
        
        if existingController.presentedViewController != nil {
            existingController.dismiss(animated: animated, completion: present)
        } else {
            present()
        }
    }
}

/// Push to NavigationController
public struct NavigationControllerPresentationRouter: PresentationRouter {
    public enum Regime {
        case push
        case replaceLast
        case asRoot
    }
    
    public var regime: Regime = .push
    public var beginFromCurrent: Bool = false
    
    public var prepareHandler: ((UIViewController)->Void)? = nil
    public var postHandler: ((UIViewController)->Void)? = nil
    
    public init(regime: Regime = .push, beginFromCurrent: Bool = false) {
        self.regime = regime
        self.beginFromCurrent = beginFromCurrent
    }
    
    public func present(_ viewController: UIViewController, on existingController: UIViewController, animated: Bool, completionHandler: @escaping (PresentationRouterResult) -> Void) {
        //1. Test - can presented
        guard let navigationController = (existingController as? UINavigationController) ?? existingController.navigationController else {
            completionHandler(.failure(DependencyRouterError.notReadyPresentingViewController("not found UINavigationController")))
            return
        }
        
        //2. Prepare
        prepareHandler?(viewController)
        
        //3. Action
        switch regime {
        case .push:
            if beginFromCurrent && navigationController.topViewController !== existingController {
                var newVCList = navigationController.viewControllers
                while !newVCList.isEmpty && newVCList.last !== existingController {
                    newVCList.removeLast()
                }
                
                newVCList.append(viewController)
                navigationController.setViewControllers(newVCList, animated: animated)
                
            } else {
                navigationController.pushViewController(viewController, animated: animated)
            }
            
        case .asRoot:
            navigationController.setViewControllers([viewController], animated: animated)
            
        case .replaceLast:
            if navigationController.viewControllers.count < 2 {
                navigationController.setViewControllers([viewController], animated: animated)
                
            } else {
                var viewControllers = navigationController.viewControllers
                
                if beginFromCurrent && navigationController.topViewController !== existingController {
                    var viewControllers = navigationController.viewControllers
                    while !viewControllers.isEmpty && viewControllers.last !== existingController {
                        viewControllers.removeLast()
                    }
                }
                
                if viewControllers.count > 1 {
                    viewControllers.removeLast()
                }
                
                viewControllers.append(viewController)
                navigationController.setViewControllers(viewControllers, animated: animated)
            }
        }
        
        //4. Post
        postHandler?(viewController)
        completionHandler(.success)
    }
}
