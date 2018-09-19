//
//  ParamsCallbackFactory.swift
//  DependencyRouter
//
//  Created by Короткий Виталий on 08.09.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import UIKit

public protocol ParamsFactoryInputSource: BaseFactoryInputSource {
    func paramsForFactoryRouter(_ routerType: CoreFactoryRouter.Type, identifier: String?, sender: Any?) -> Any?
}

public protocol CallbackFactoryInputSource: BaseFactoryInputSource {
    func callbackForFactoryRouter(_ routerType: CoreFactoryRouter.Type, identifier: String?, sender: Any?) -> Any?
}


//MARK: FactoryRouter
public protocol ParamsFactoryRouter: FactoryRouter, FactorySupportInputSource {
    associatedtype VCType: UIViewController
    associatedtype ParamsType
    
    func setupViewController(_ viewController: VCType, params: ParamsType)
    func defaultPresentation(params: ParamsType) -> PresentationRouter
}

public protocol CallbackFactoryRouter: FactoryRouter, FactorySupportInputSource {
    associatedtype VCType: UIViewController
    associatedtype CallbackType
    
    func setupViewController(_ viewController: VCType, callback: CallbackType)
}

public protocol ParamsWithCallbackFactoryRouter: FactoryRouter, FactorySupportInputSource {
    associatedtype VCType: UIViewController
    associatedtype ParamsType
    associatedtype CallbackType
    
    func setupViewController(_ viewController: VCType, params: ParamsType, callback: CallbackType)
    func defaultPresentation(params: ParamsType) -> PresentationRouter
}

//MARK: Helpers
extension ParamsFactoryRouter {
    public func defaultPresentation(params: ParamsType) -> PresentationRouter {
        return defaultPresentation()
    }
    
    public static func createParams(_ params: ParamsType) -> ParamsType {
        return params
    }
}

extension CallbackFactoryRouter {
    public static func useCallback(_ callback: CallbackType) -> CallbackType {
        return callback
    }
}

extension ParamsWithCallbackFactoryRouter {
    public func defaultPresentation(params: ParamsType) -> PresentationRouter {
        return defaultPresentation()
    }
    
    public static func createParams(_ params: ParamsType) -> ParamsType {
        return params
    }
    
    public static func useCallback(_ callback: CallbackType) -> CallbackType {
        return callback
    }
}

//MARK: Factory InputSource Store
public struct ParamsFactoryInputSourceStore: ParamsFactoryInputSource {
    public let routerType: CoreFactoryRouter.Type
    public let params: Any
    
    public init(_ routerType: CoreFactoryRouter.Type, params: Any) {
        self.routerType = routerType
        self.params = params
    }
    
    public func paramsForFactoryRouter(_ routerType: CoreFactoryRouter.Type, identifier: String?, sender: Any?) -> Any? {
        if routerType == self.routerType {
            return params
        } else {
            return nil
        }
    }
}

public struct CallbackFactoryInputSourceStore: CallbackFactoryInputSource {
    public let routerType: CoreFactoryRouter.Type
    public let callback: Any
    
    public init(_ routerType: CoreFactoryRouter.Type, callback: Any) {
        self.routerType = routerType
        self.callback = callback
    }
    
    public func callbackForFactoryRouter(_ routerType: CoreFactoryRouter.Type, identifier: String?, sender: Any?) -> Any? {
        if routerType == self.routerType {
            return callback
        } else {
            return nil
        }
    }
}

public class WeakCallbackFactoryInputSourceStore: CallbackFactoryInputSource {
    public let routerType: CoreFactoryRouter.Type
    public weak var callback: AnyObject?
    
    public init(_ routerType: CoreFactoryRouter.Type, callback: AnyObject) {
        self.routerType = routerType
        self.callback = callback
    }
    
    public func callbackForFactoryRouter(_ routerType: CoreFactoryRouter.Type, identifier: String?, sender: Any?) -> Any? {
        if routerType == self.routerType {
            return callback
        } else {
            return nil
        }
    }
}



//MARK: Support Builder
extension BuilderRouterReadySetup where FR: ParamsFactoryRouter {
    public func setup(params: FR.ParamsType) -> BuilderRouterReadyPresent<VC> {
        let factory = self.factory
        let findedViewController: FR.VCType = dependencyRouterFindViewControllerOrFatalError(viewController)
        
        factory.setupViewController(findedViewController, params: params)
        return .init(viewController: viewController, default: factory.defaultPresentation(params: params))
    }
}

extension BuilderRouterReadySetup where FR: CallbackFactoryRouter {
    public func setup(callback: FR.CallbackType) -> BuilderRouterReadyPresent<VC> {
        let factory = self.factory
        let findedViewController: FR.VCType = dependencyRouterFindViewControllerOrFatalError(viewController)
        
        factory.setupViewController(findedViewController, callback: callback)
        return .init(viewController: viewController, default: factory.defaultPresentation())
    }
}

extension BuilderRouterReadySetup where FR: ParamsWithCallbackFactoryRouter {
    public func setup(params: FR.ParamsType, callback: FR.CallbackType) -> BuilderRouterReadyPresent<VC> {
        let factory = self.factory
        let findedViewController: FR.VCType = dependencyRouterFindViewControllerOrFatalError(viewController)
        
        factory.setupViewController(findedViewController, params: params, callback: callback)
        return .init(viewController: viewController, default: factory.defaultPresentation(params: params))
    }
}

extension BuilderRouterReadyCreate where FR: CreatorFactoryRouter, FR: ParamsFactoryRouter {
    public func createAndSetup(params: FR.ParamsType) -> BuilderRouterReadyPresent<FR.VCCreateType> {
        let factory = self.factory()
        let viewController = factory.createViewController()
        let findedViewController: FR.VCType = dependencyRouterFindViewControllerOrFatalError(viewController)
        
        factory.setupViewController(findedViewController, params: params)
        return .init(viewController: viewController, default: factory.defaultPresentation(params: params))
    }
}

extension BuilderRouterReadyCreate where FR: CreatorFactoryRouter, FR: CallbackFactoryRouter {
    public func createAndSetup(callback: FR.CallbackType) -> BuilderRouterReadyPresent<FR.VCCreateType> {
        let factory = self.factory()
        let viewController = factory.createViewController()
        let findedViewController: FR.VCType = dependencyRouterFindViewControllerOrFatalError(viewController)
        
        factory.setupViewController(findedViewController, callback: callback)
        return .init(viewController: viewController, default: factory.defaultPresentation())
    }
}

extension BuilderRouterReadyCreate where FR: CreatorFactoryRouter, FR: ParamsWithCallbackFactoryRouter {
    public func createAndSetup(params: FR.ParamsType, callback: FR.CallbackType) -> BuilderRouterReadyPresent<FR.VCCreateType> {
        let factory = self.factory()
        let viewController = factory.createViewController()
        let findedViewController: FR.VCType = dependencyRouterFindViewControllerOrFatalError(viewController)
        
        factory.setupViewController(findedViewController, params: params, callback: callback)
        return .init(viewController: viewController, default: factory.defaultPresentation(params: params))
    }
}

extension PresentNavigationRouter {
    //MARK: Support Present NavigationRouter - input params
    func present<FR: AutoFactoryRouter & CreatorFactoryRouter & ParamsFactoryRouter>(_ routerType: FR.Type, params: FR.ParamsType, presentation: PresentationRouter? = nil, animated: Bool = true) {
        if let viewController = associatedViewController {
            BuilderRouter(routerType).createAndSetup(params: params).present(on: viewController, presentation: presentation, animated: animated)
        }
    }
    
    func present<FR: AutoFactoryRouter & CreatorFactoryRouter & CallbackFactoryRouter>(_ routerType: FR.Type, callback: FR.CallbackType, presentation: PresentationRouter? = nil, animated: Bool = true) {
        if let viewController = associatedViewController {
            BuilderRouter(routerType).createAndSetup(callback: callback).present(on: viewController, presentation: presentation, animated: animated)
        }
    }
    
    func present<FR: AutoFactoryRouter & CreatorFactoryRouter & ParamsWithCallbackFactoryRouter>(_ routerType: FR.Type, params: FR.ParamsType, callback: FR.CallbackType, presentation: PresentationRouter? = nil, animated: Bool = true) {
        if let viewController = associatedViewController {
            BuilderRouter(routerType).createAndSetup(params: params, callback: callback).present(on: viewController, presentation: presentation, animated: animated)
        }
    }
    
    //MARK: Support Present NavigationRouter - input source
    func present<FR: AutoFactoryRouter & CreatorFactoryRouter & ParamsFactoryRouter>(_ routerType: FR.Type, presentation: PresentationRouter? = nil, animated: Bool = true) {
        if let viewController = associatedViewController {
            BuilderRouter(routerType).create().setup(sourceList: sourceList).present(on: viewController, presentation: presentation, animated: animated)
        }
    }
    
    func present<FR: AutoFactoryRouter & CreatorFactoryRouter & CallbackFactoryRouter>(_ routerType: FR.Type, presentation: PresentationRouter? = nil, animated: Bool = true) {
        if let viewController = associatedViewController {
            BuilderRouter(routerType).create().setup(sourceList: sourceList).present(on: viewController, presentation: presentation, animated: animated)
        }
    }
    
    func present<FR: AutoFactoryRouter & CreatorFactoryRouter & ParamsWithCallbackFactoryRouter>(_ routerType: FR.Type, presentation: PresentationRouter? = nil, animated: Bool = true) {
        if let viewController = associatedViewController {
            BuilderRouter(routerType).create().setup(sourceList: sourceList).present(on: viewController, presentation: presentation, animated: animated)
        }
    }
}

//MARK: Support InputSource
private func findParams<ParamsType>(factoryType: CoreFactoryRouter.Type, sourceList: [BaseFactoryInputSource], identifier: String?, sender: Any?) throws -> ParamsType {
    for inputSourceAny in sourceList {
        guard let inputSource = inputSourceAny as? ParamsFactoryInputSource else { continue }
        guard let anyParams = inputSource.paramsForFactoryRouter(factoryType, identifier: identifier, sender: sender) else { continue }
        
        guard let params = anyParams as? ParamsType else {
            throw DependencyRouterError.inputDataInvalidType("Params", type(of: anyParams), required: ParamsType.self)
        }
        
        return params
    }
    
    throw DependencyRouterError.inputSourceNotFound(ParamsFactoryInputSource.self)
}

private func findCallback<CallbackType>(factoryType: CoreFactoryRouter.Type, sourceList: [BaseFactoryInputSource], identifier: String?, sender: Any?) throws -> CallbackType {
    for inputSourceAny in sourceList {
        guard let inputSource = inputSourceAny as? CallbackFactoryInputSource else { continue }
        guard let anyCallback = inputSource.callbackForFactoryRouter(factoryType, identifier: identifier, sender: sender) else { continue }
        
        guard let callback = anyCallback as? CallbackType else {
            throw DependencyRouterError.inputDataInvalidType("Callback", type(of: anyCallback), required: CallbackType.self)
        }
        
        return callback
    }
    
    throw DependencyRouterError.inputSourceNotFound(CallbackFactoryInputSource.self)
}

extension ParamsFactoryRouter {
    public func coreSetup(_ viewController: UIViewController, sourceList: [BaseFactoryInputSource], identifier: String?, sender: Any?) throws {
        guard let viewController = viewController as? VCType else {
            throw DependencyRouterError.viewControllerNotFound(VCType.self)
        }
        
        let params: ParamsType = try findParams(factoryType: type(of: self), sourceList: sourceList, identifier: identifier, sender: sender)
  
        setupViewController(viewController, params: params)
    }
}

extension CallbackFactoryRouter {
    public func coreSetup(_ viewController: UIViewController, sourceList: [BaseFactoryInputSource], identifier: String?, sender: Any?) throws {
        guard let viewController = viewController as? VCType else {
            throw DependencyRouterError.viewControllerNotFound(VCType.self)
        }
        
        let callback: CallbackType = try findCallback(factoryType: type(of: self), sourceList: sourceList, identifier: identifier, sender: sender)
        
        setupViewController(viewController, callback: callback)
    }
}

extension ParamsWithCallbackFactoryRouter {
    public func coreSetup(_ viewController: UIViewController, sourceList: [BaseFactoryInputSource], identifier: String?, sender: Any?) throws {
        guard let viewController = viewController as? VCType else {
            throw DependencyRouterError.viewControllerNotFound(VCType.self)
        }
        
        let params: ParamsType = try findParams(factoryType: type(of: self), sourceList: sourceList, identifier: identifier, sender: sender)
        let callback: CallbackType = try findCallback(factoryType: type(of: self), sourceList: sourceList, identifier: identifier, sender: sender)
        
        setupViewController(viewController, params: params, callback: callback)
    }
}
