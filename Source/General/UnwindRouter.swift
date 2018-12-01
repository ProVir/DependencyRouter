//
//  UnwindRouter.swift
//  DependencyRouter
//
//  Created by Короткий Виталий on 18.09.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import UIKit

public protocol CallbackUnwindInputSource: BaseFactoryInputSource {
    func callbackForUnwindRouter(_ unwindType: CoreUnwindCallbackRouter.Type, segueIdentifier: String?) -> Any?
}


public protocol UnwindResultRouter {
    associatedtype VCType: UIViewController
    associatedtype ResultType
    
    static func unwindGetResult(_ viewController: VCType, segueIdentifier: String?) -> ResultType?
}

public protocol UnwindCallbackRouter: CoreUnwindCallbackRouter {
    associatedtype VCType: UIViewController
    associatedtype CallbackType
    
    static func unwindUseCallback(_ viewController: VCType, callback: CallbackType, segueIdentifier: String?)
}

public protocol SupportUnwindRouterViewController: CoreUnwindRouterViewController {
    associatedtype UnwindRouter: UnwindCallbackRouter
}

public protocol SelfUnwindRouterViewController: CoreUnwindRouterViewController, CoreUnwindCallbackRouter {
    associatedtype CallbackType
    func unwindUseCallback(callback: CallbackType, segueIdentifier: String?)
}


extension UnwindCallbackRouter {
    public static func useCallback(_ callback: CallbackType) -> CallbackType {
        return callback
    }
}

extension SelfUnwindRouterViewController {
    public static func useCallback(_ callback: CallbackType) -> CallbackType {
        return callback
    }
}

//MARK: Support router
extension Router {
    public static func unwindSegue<Unwind: UnwindResultRouter>(_ unwindType: Unwind.Type, segue: UIStoryboardSegue) -> Unwind.ResultType? {
        guard let viewController: Unwind.VCType = try? dependencyRouterFindViewController(segue.source) else {
            return nil
        }

        return Unwind.unwindGetResult(viewController, segueIdentifier: segue.identifier)
    }
    
    public static func unwindSegue<Unwind: UnwindCallbackRouter>(_ unwindType: Unwind.Type, segue: UIStoryboardSegue, callback: Unwind.CallbackType) -> Bool {
        guard let viewController: Unwind.VCType = try? dependencyRouterFindViewController(segue.source) else {
            return false
        }
        
        Unwind.unwindUseCallback(viewController, callback: callback, segueIdentifier: segue.identifier)
        return true
    }
    
    public static func unwindSegue<VC: UIViewController & SelfUnwindRouterViewController>(_ unwindType: VC.Type, segue: UIStoryboardSegue, callback: VC.CallbackType) -> Bool {
        guard let viewController: VC = try? dependencyRouterFindViewController(segue.source) else {
            return false
        }
        
        viewController.unwindUseCallback(callback: callback, segueIdentifier: segue.identifier)
        return true
    }
    
    @discardableResult
    public static func unwindSegue(_ segue: UIStoryboardSegue, source: CallbackUnwindInputSource) -> Bool {
        return unwindSegue(segue, sourceList: [source])
    }
    
    @discardableResult
    public static func unwindSegue(_ segue: UIStoryboardSegue, sourceList: [BaseFactoryInputSource]) -> Bool {
        guard let viewController = dependencyRouterFindUnwindRouterViewController(segue.source) else {
            return false
        }
        
        let unwindType = viewController.unwindRouterType
        
        do {
            try DependencyRouterError.tryAsAssertionFailure {
                try unwindType.coreUnwindUseCallback(viewController, sourceList: sourceList, segueIdentifier: segue.identifier)
            }
        } catch {
            return false
        }
        
        return true
    }
}


//MARK: - Core
public protocol CoreUnwindCallbackRouter {
    static func coreUnwindUseCallback(_ viewController: UIViewController, sourceList: [BaseFactoryInputSource], segueIdentifier: String?) throws
}

public protocol CoreUnwindRouterViewController: class {
    var unwindRouterType: CoreUnwindCallbackRouter.Type { get }
}

extension SupportUnwindRouterViewController {
    public var unwindRouterType: CoreUnwindCallbackRouter.Type {
        return UnwindRouter.self
    }
}

private func findCallback<CallbackType>(unwindType: CoreUnwindCallbackRouter.Type, sourceList: [BaseFactoryInputSource], segueIdentifier: String?) throws -> CallbackType {
    for inputSourceAny in sourceList {
        guard let inputSource = inputSourceAny as? CallbackUnwindInputSource else { continue }
        guard let anyCallback = inputSource.callbackForUnwindRouter(unwindType, segueIdentifier: segueIdentifier) else { continue }
        
        guard let callback = anyCallback as? CallbackType else {
            throw DependencyRouterError.inputDataInvalidType("Callback", type(of: anyCallback), required: CallbackType.self)
        }
        
        return callback
    }
    
    throw DependencyRouterError.inputSourceNotFound(CallbackUnwindInputSource.self)
}

extension UnwindCallbackRouter {
    public static func coreUnwindUseCallback(_ viewController: UIViewController, sourceList: [BaseFactoryInputSource], segueIdentifier: String?) throws {
        guard let viewController = viewController as? VCType else {
            throw DependencyRouterError.viewControllerNotFound(VCType.self)
        }
        
        let callback: CallbackType = try findCallback(unwindType: self, sourceList: sourceList, segueIdentifier: segueIdentifier)
        
        unwindUseCallback(viewController, callback: callback, segueIdentifier: segueIdentifier)
    }
}

extension SelfUnwindRouterViewController {
    public var unwindRouterType: CoreUnwindCallbackRouter.Type {
        return Self.self
    }
    
    public static func coreUnwindUseCallback(_ viewController: UIViewController, sourceList: [BaseFactoryInputSource], segueIdentifier: String?) throws {
        guard let viewController = viewController as? Self else {
            throw DependencyRouterError.viewControllerNotFound(self)
        }
        
        let callback: CallbackType = try findCallback(unwindType: self, sourceList: sourceList, segueIdentifier: segueIdentifier)
        
        viewController.unwindUseCallback(callback: callback, segueIdentifier: segueIdentifier)
    }
}

//MARK: Helpers
public func dependencyRouterFindUnwindRouterViewController(_ viewController: UIViewController) -> (UIViewController & CoreUnwindRouterViewController)? {
    if let vc = viewController as? UIViewController & CoreUnwindRouterViewController {
        return vc
    } else if let vc: UIViewController & CoreUnwindRouterViewController = (viewController as? ContainerViewControllerSupportRouter)?.findViewController() {
        return vc
    } else {
        return nil
    }
}
