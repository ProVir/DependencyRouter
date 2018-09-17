//
//  ParamsCallbackFactory.swift
//  DependencyRouter
//
//  Created by Короткий Виталий on 08.09.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import UIKit

public protocol ParamsFactoryRouter: FactoryRouter {
    associatedtype VCType: UIViewController
    associatedtype ParamsType
    
    func setupViewController(_ viewController: VCType, params: ParamsType)
    func defaultPresentation(params: ParamsType) -> PresentationRouter
}

public protocol CallbackFactoryRouter: FactoryRouter {
    associatedtype VCType: UIViewController
    associatedtype CallbackType
    
    func setupViewController(_ viewController: VCType, callback: CallbackType)
}

public protocol ParamsWithCallbackFactoryRouter: FactoryRouter {
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



