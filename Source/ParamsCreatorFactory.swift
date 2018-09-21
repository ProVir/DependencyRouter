//
//  ParamsCreatorFactory.swift
//  DependencyRouter
//
//  Created by Короткий Виталий on 09.09.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import UIKit

public protocol ParamsCreatorFactoryRouter: FactoryRouter {
    associatedtype VCType: UIViewController
    associatedtype ParamsType
    
    func createAndSetupViewController(params: ParamsType) -> VCType
    func presentation(params: ParamsType) -> PresentationRouter
}

public protocol ParamsCreatorWithCallbackFactoryRouter: FactoryRouter {
    associatedtype VCType: UIViewController
    associatedtype ParamsType
    associatedtype CallbackType
    
    func createAndSetupViewController(params: ParamsType, callback: CallbackType) -> VCType
    func presentation(params: ParamsType) -> PresentationRouter
}

public protocol BlankCreatorWithCallbackFactoryRouter: FactoryRouter {
    associatedtype VCType: UIViewController
    associatedtype CallbackType
    
    func createAndSetupViewController(callback: CallbackType) -> VCType
}

public typealias AutoParamsCreatorFactoryRouter             = AutoFactoryRouter & ParamsCreatorFactoryRouter
public typealias AutoParamsCreatorWithCallbackFactoryRouter = AutoFactoryRouter & ParamsCreatorWithCallbackFactoryRouter
public typealias AutoBlankCreatorWithCallbackFactoryRouter  = AutoFactoryRouter & BlankCreatorWithCallbackFactoryRouter

public typealias LightParamsCreatorFactoryRouter             = LightFactoryRouter & ParamsCreatorFactoryRouter
public typealias LightParamsCreatorWithCallbackFactoryRouter = LightFactoryRouter & ParamsCreatorWithCallbackFactoryRouter
public typealias LightBlankCreatorWithCallbackFactoryRouter  = LightFactoryRouter & BlankCreatorWithCallbackFactoryRouter


//MARK: Helpers
extension ParamsCreatorFactoryRouter {
    public func presentation(params: ParamsType) -> PresentationRouter {
        return presentation()
    }
    
    public static func createParams(_ params: ParamsType) -> ParamsType {
        return params
    }
}

extension ParamsCreatorWithCallbackFactoryRouter {
    public func presentation(params: ParamsType) -> PresentationRouter {
        return presentation()
    }
    
    public static func createParams(_ params: ParamsType) -> ParamsType {
        return params
    }
    
    public static func useCallback(_ callback: CallbackType) -> CallbackType {
        return callback
    }
}

extension BlankCreatorWithCallbackFactoryRouter {
    public static func useCallback(_ callback: CallbackType) -> CallbackType {
        return callback
    }
}



//MARK: Support Builder
extension BuilderRouterReadyCreate where FR: ParamsCreatorFactoryRouter {
    public func createAndSetup(params: FR.ParamsType) -> BuilderRouterReadyPresent<FR.VCType> {
        let factory = self.factory()
        let vc = factory.createAndSetupViewController(params: params)
        return .init(viewController: vc, default: factory.presentation(params: params))
    }
}

extension BuilderRouterReadyCreate where FR: ParamsCreatorWithCallbackFactoryRouter {
    public func createAndSetup(params: FR.ParamsType, callback: FR.CallbackType) -> BuilderRouterReadyPresent<FR.VCType> {
        let factory = self.factory()
        let vc = factory.createAndSetupViewController(params: params, callback: callback)
        return .init(viewController: vc, default: factory.presentation(params: params))
    }
}

extension BuilderRouterReadyCreate where FR: BlankCreatorWithCallbackFactoryRouter {
    public func createAndSetup(callback: FR.CallbackType) -> BuilderRouterReadyPresent<FR.VCType> {
        let factory = self.factory()
        let vc = factory.createAndSetupViewController(callback: callback)
        return .init(viewController: vc, default: factory.presentation())
    }
}


//MARK: Support Present NavigationRouter - input params
extension SimplePresentNavigationRouter {
    public func simplePresent<FR: AutoParamsCreatorFactoryRouter>(_ routerType: FR.Type, params: FR.ParamsType, presentation: PresentationRouter? = nil, animated: Bool = true) {
        if let viewController = associatedViewController {
            BuilderRouter(routerType).createAndSetup(params: params).present(on: viewController, presentation: presentation, animated: animated)
        }
    }
    
    public func simplePresent<FR: AutoParamsCreatorWithCallbackFactoryRouter>(_ routerType: FR.Type, params: FR.ParamsType, callback: FR.CallbackType, presentation: PresentationRouter? = nil, animated: Bool = true) {
        if let viewController = associatedViewController {
            BuilderRouter(routerType).createAndSetup(params: params, callback: callback).present(on: viewController, presentation: presentation, animated: animated)
        }
    }
    
    public func simplePresent<FR: AutoBlankCreatorWithCallbackFactoryRouter>(_ routerType: FR.Type, callback: FR.CallbackType, presentation: PresentationRouter? = nil, animated: Bool = true) {
        if let viewController = associatedViewController {
            BuilderRouter(routerType).createAndSetup(callback: callback).present(on: viewController, presentation: presentation, animated: animated)
        }
    }
}

