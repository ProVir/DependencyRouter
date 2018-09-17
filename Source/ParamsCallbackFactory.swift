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
        let factory = self.factory
        let viewController = factory.createViewController()
        let findedViewController: FR.VCType = dependencyRouterFindViewControllerOrFatalError(viewController)
        
        factory.setupViewController(findedViewController, params: params)
        return .init(viewController: viewController, default: factory.defaultPresentation(params: params))
    }
}

extension BuilderRouterReadyCreate where FR: CreatorFactoryRouter, FR: CallbackFactoryRouter {
    public func createAndSetup(callback: FR.CallbackType) -> BuilderRouterReadyPresent<FR.VCCreateType> {
        let factory = self.factory
        let viewController = factory.createViewController()
        let findedViewController: FR.VCType = dependencyRouterFindViewControllerOrFatalError(viewController)
        
        factory.setupViewController(findedViewController, callback: callback)
        return .init(viewController: viewController, default: factory.defaultPresentation())
    }
}

extension BuilderRouterReadyCreate where FR: CreatorFactoryRouter, FR: ParamsWithCallbackFactoryRouter {
    public func createAndSetup(params: FR.ParamsType, callback: FR.CallbackType) -> BuilderRouterReadyPresent<FR.VCCreateType> {
        let factory = self.factory
        let viewController = factory.createViewController()
        let findedViewController: FR.VCType = dependencyRouterFindViewControllerOrFatalError(viewController)
        
        factory.setupViewController(findedViewController, params: params, callback: callback)
        return .init(viewController: viewController, default: factory.defaultPresentation(params: params))
    }
}

//MARK: Support InputSource
private func findParams<ParamsType>(factoryType: CoreFactoryRouter.Type, sourceList: [BaseFactoryInputSource], identifier: String?, sender: Any?) throws -> ParamsType {
    guard let inputSource = sourceList.first(where: { $0 is ParamsFactoryInputSource }) as? ParamsFactoryInputSource else {
        throw DependencyRouterError.inputSourceNotFound(ParamsFactoryInputSource.self)
    }
    
    guard let anyParams = inputSource.paramsForFactoryRouter(factoryType, identifier: identifier, sender: sender) else {
        throw DependencyRouterError.inputDataNotFound("Params")
    }
    
    guard let params = anyParams as? ParamsType else {
        throw DependencyRouterError.inputDataInvalidType("Params", type(of: anyParams), required: ParamsType.self)
    }
    
    return params
}

private func findCallback<CallbackType>(factoryType: CoreFactoryRouter.Type, sourceList: [BaseFactoryInputSource], identifier: String?, sender: Any?) throws -> CallbackType {
    guard let inputSource = sourceList.first(where: { $0 is CallbackFactoryInputSource }) as? CallbackFactoryInputSource else {
        throw DependencyRouterError.inputSourceNotFound(CallbackFactoryInputSource.self)
    }
    
    guard let anyCallback = inputSource.callbackForFactoryRouter(factoryType, identifier: identifier, sender: sender) else {
        throw DependencyRouterError.inputDataNotFound("Callback")
    }
    
    guard let callback = anyCallback as? CallbackType else {
        throw DependencyRouterError.inputDataInvalidType("Callback", type(of: anyCallback), required: CallbackType.self)
    }
    
    return callback
}

extension ParamsFactoryRouter {
    public func setup(_ viewController: UIViewController, sourceList: [BaseFactoryInputSource], identifier: String?, sender: Any?) throws {
        let viewController: VCType = try dependencyRouterFindViewController(viewController)
        let params: ParamsType = try findParams(factoryType: type(of: self), sourceList: sourceList, identifier: identifier, sender: sender)
  
        setupViewController(viewController, params: params)
    }
}

extension CallbackFactoryRouter {
    public func setup(_ viewController: UIViewController, sourceList: [BaseFactoryInputSource], identifier: String?, sender: Any?) throws {
        let viewController: VCType = try dependencyRouterFindViewController(viewController)
        let callback: CallbackType = try findCallback(factoryType: type(of: self), sourceList: sourceList, identifier: identifier, sender: sender)
        
        setupViewController(viewController, callback: callback)
    }
}

extension ParamsWithCallbackFactoryRouter {
    public func setup(_ viewController: UIViewController, sourceList: [BaseFactoryInputSource], identifier: String?, sender: Any?) throws {
        let viewController: VCType = try dependencyRouterFindViewController(viewController)
        let params: ParamsType = try findParams(factoryType: type(of: self), sourceList: sourceList, identifier: identifier, sender: sender)
        let callback: CallbackType = try findCallback(factoryType: type(of: self), sourceList: sourceList, identifier: identifier, sender: sender)
        
        setupViewController(viewController, params: params, callback: callback)
    }
}

