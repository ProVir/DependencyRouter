//
//  SimplePresentationActions.swift
//  DependencyRouter
//
//  Created by Короткий Виталий on 11.09.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import UIKit

/// Shared UIAdaptivePresentationControllerDelegate in regime no daptive for iPhone
public class NoAdaptivePresentationStyleHelper: NSObject, UIAdaptivePresentationControllerDelegate {
    public static var shared = NoAdaptivePresentationStyleHelper()
    public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}

/// Assert if use - used as default when require always use own
public struct NotPresentationAction: PresentationAction {
    public init() { }
    
    public func present(_ viewController: UIViewController, on existingController: UIViewController, animated: Bool, completionHandler: @escaping (PresentationActionResult) -> Void) {
        assertionFailure("You need use valid PresentationAction, don't use NotPresentationAction.")
        completionHandler(.failure(DependencyRouterError.notReadyPresentingViewController("need use valid PresentationAction, don't use NotPresentationAction.")))
    }
}

/// Show used UIViewController.show(_ vc: UIViewController, sender: Any?), as default
public struct ShowPresentationAction: PresentationAction {
    public var prepareHandler: ((UIViewController)->Void)? = nil
    public var postHandler: ((UIViewController)->Void)? = nil
    
    public init() { }
    
    public func present(_ viewController: UIViewController, on existingController: UIViewController, animated: Bool, completionHandler: @escaping (PresentationActionResult) -> Void) {
        
        prepareHandler?(viewController)
        
        if !animated { UIView.setAnimationsEnabled(false) }
        existingController.show(viewController, sender: nil)
        if !animated { UIView.setAnimationsEnabled(true) }
        
        postHandler?(viewController)
        completionHandler(.success)
    }
}

/// Present ViewController as Modal
public struct ModalPresentationAction: PresentationAction {
    public enum PopoverSourceView {
        case barButtonItem(UIBarButtonItem)
        case view(UIView, CGRect)
    }
    
    public enum CloseLeftButton {
        case none
        case system(UIBarButtonItem.SystemItem)
        case title(String, UIBarButtonItem.Style)
        case image(UIImage)
        
        public var isNeed: Bool {
            switch self {
            case .none: return false
            default: return true
            }
        }
    }
    
    public var canAutoWrappedNavigtionController: Bool = false
    public var canDismissOtherPresented: Bool = false
    public var noAdaptivePresentationStyle: Bool = false
    
    public var prepareHandler: ((UIViewController)->Void)? = nil
    public var postHandler: ((UIViewController)->Void)? = nil
    
    public init() { }
    
    public init(autoWrapped: Bool, dismissOtherPresented: Bool = false, noAdaptive: Bool = false, prepareHandler: ((UIViewController)->Void)? = nil) {
        self.canAutoWrappedNavigtionController = autoWrapped
        self.canDismissOtherPresented = dismissOtherPresented
        self.noAdaptivePresentationStyle = noAdaptive
        self.prepareHandler = prepareHandler
    }
    
    public init(autoWrapped: Bool, dismissOtherPresented: Bool = false, noAdaptive: Bool = false, presentationStyle: UIModalPresentationStyle, closeLeftButton: CloseLeftButton = .none) {
        self.canAutoWrappedNavigtionController = autoWrapped
        self.canDismissOtherPresented = dismissOtherPresented
        self.noAdaptivePresentationStyle = noAdaptive
        
        self.prepareHandler = { viewController in
            viewController.modalPresentationStyle = presentationStyle
            
            if closeLeftButton.isNeed, let firstVC = (viewController as? UINavigationController)?.viewControllers.first {
                let selDismiss = NSSelectorFromString("dismissUseRouter")
                
                let item: UIBarButtonItem
                switch closeLeftButton {
                case .none: return
                case .system(let button):
                    item = UIBarButtonItem(barButtonSystemItem: button, target: firstVC, action: selDismiss)
                case .title(let title, let style):
                    item = UIBarButtonItem(title: title, style: style, target: firstVC, action: selDismiss)
                case .image(let image):
                    item = UIBarButtonItem(image: image, style: .plain, target: firstVC, action: selDismiss)
                }
                
                firstVC.navigationItem.leftBarButtonItem = item
            }
        }
    }
    
    public init(autoWrapped: Bool, dismissOtherPresented: Bool = false, noAdaptive: Bool = false, popoverSourceView: PopoverSourceView, permittedArrowDirections: UIPopoverArrowDirection = .any) {
        self.canAutoWrappedNavigtionController = autoWrapped
        self.canDismissOtherPresented = dismissOtherPresented
        self.noAdaptivePresentationStyle = noAdaptive
        
        self.prepareHandler = { viewController in
            viewController.modalPresentationStyle = .popover
            
            if let popoverController = viewController.popoverPresentationController {
                switch popoverSourceView {
                case let .barButtonItem(barItem):
                    popoverController.barButtonItem = barItem
                    
                case let .view(view, rect):
                    popoverController.sourceView = view
                    popoverController.sourceRect = rect
                }
                
                popoverController.permittedArrowDirections = permittedArrowDirections
            }
        }
    }
    
    public func present(_ viewController: UIViewController, on existingController: UIViewController, animated: Bool, completionHandler: @escaping (PresentationActionResult) -> Void) {
        //1. Prepare
        let presentViewController: UIViewController
        if canAutoWrappedNavigtionController && !(viewController is UINavigationController) {
            presentViewController = UINavigationController(rootViewController: viewController)
        } else {
            presentViewController = viewController
        }
        
        if noAdaptivePresentationStyle {
            presentViewController.presentationController?.delegate = NoAdaptivePresentationStyleHelper.shared
        }
        
        prepareHandler?(presentViewController)
        
        //2. Present
        let postHandler = self.postHandler
        func present() {
            existingController.present(presentViewController, animated: animated) {
                postHandler?(presentViewController)
                completionHandler(.success)
            }
        }
        
        if canDismissOtherPresented, existingController.presentedViewController != nil {
            existingController.dismiss(animated: animated, completion: present)
        } else {
            present()
        }
    }
}

/// Push to NavigationController
public struct NavigationControllerPresentationAction: PresentationAction {
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
    
    public func present(_ viewController: UIViewController, on existingController: UIViewController, animated: Bool, completionHandler: @escaping (PresentationActionResult) -> Void) {
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

