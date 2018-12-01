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
    
    func createAndSetupViewController(params: ParamsType) throws -> VCType
    func presentationAction(params: ParamsType) -> PresentationAction
}

public protocol ParamsCreatorWithCallbackFactoryRouter: FactoryRouter {
    associatedtype VCType: UIViewController
    associatedtype ParamsType
    associatedtype CallbackType
    
    func createAndSetupViewController(params: ParamsType, callback: CallbackType) throws -> VCType
    func presentationAction(params: ParamsType) -> PresentationAction
}

public protocol BlankCreatorWithCallbackFactoryRouter: FactoryRouter {
    associatedtype VCType: UIViewController
    associatedtype CallbackType
    
    func createAndSetupViewController(callback: CallbackType) throws -> VCType
}

public typealias AutoParamsCreatorFactoryRouter             = AutoFactoryRouter & ParamsCreatorFactoryRouter
public typealias AutoParamsCreatorWithCallbackFactoryRouter = AutoFactoryRouter & ParamsCreatorWithCallbackFactoryRouter
public typealias AutoBlankCreatorWithCallbackFactoryRouter  = AutoFactoryRouter & BlankCreatorWithCallbackFactoryRouter

public typealias LightParamsCreatorFactoryRouter             = LightFactoryRouter & ParamsCreatorFactoryRouter
public typealias LightParamsCreatorWithCallbackFactoryRouter = LightFactoryRouter & ParamsCreatorWithCallbackFactoryRouter
public typealias LightBlankCreatorWithCallbackFactoryRouter  = LightFactoryRouter & BlankCreatorWithCallbackFactoryRouter


//MARK: Helpers
extension ParamsCreatorFactoryRouter {
    public func presentationAction(params: ParamsType) -> PresentationAction {
        return presentationAction()
    }
    
    public static func createParams(_ params: ParamsType) -> ParamsType {
        return params
    }
}

extension ParamsCreatorWithCallbackFactoryRouter {
    public func presentationAction(params: ParamsType) -> PresentationAction {
        return presentationAction()
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

// MARK: Support Builder
extension BuilderRouterReadyCreate where FR: ParamsCreatorFactoryRouter {
    public func createAndSetup(params: FR.ParamsType) -> BuilderRouterReadyPresent<FR.VCType> {
        do {
            let factory = self.factory()
            let vc = try factory.createAndSetupViewController(params: params)
            return .init(viewController: vc, default: factory.presentationAction(params: params))
        } catch {
            return .init(error: error)
        }
    }
}

extension BuilderRouterReadyCreate where FR: ParamsCreatorWithCallbackFactoryRouter {
    public func createAndSetup(params: FR.ParamsType, callback: FR.CallbackType) -> BuilderRouterReadyPresent<FR.VCType> {
        do {
            let factory = self.factory()
            let vc = try factory.createAndSetupViewController(params: params, callback: callback)
            return .init(viewController: vc, default: factory.presentationAction(params: params))
        } catch {
            return .init(error: error)
        }
    }
}

extension BuilderRouterReadyCreate where FR: BlankCreatorWithCallbackFactoryRouter {
    public func createAndSetup(callback: FR.CallbackType) -> BuilderRouterReadyPresent<FR.VCType> {
        do {
            let factory = self.factory()
            let vc = try factory.createAndSetupViewController(callback: callback)
            return .init(viewController: vc, default: factory.presentationAction())
        } catch {
            return .init(error: error)
        }
    }
}


//MARK: Support Present NavigationRouter - input params
extension SimplePresentNavigationRouter {
    public func simplePresent<FR: AutoParamsCreatorFactoryRouter>(_ routerType: FR.Type, params: FR.ParamsType, action: PresentationAction? = nil, animated: Bool = true) {
        BuilderRouter(routerType).createAndSetup(params: params).present(on: associatedViewController, action: action, animated: animated)
    }
    
    public func simplePresent<FR: AutoParamsCreatorWithCallbackFactoryRouter>(_ routerType: FR.Type, params: FR.ParamsType, callback: FR.CallbackType, action: PresentationAction? = nil, animated: Bool = true) {
        BuilderRouter(routerType).createAndSetup(params: params, callback: callback).present(on: associatedViewController, action: action, animated: animated)
    }
    
    public func simplePresent<FR: AutoBlankCreatorWithCallbackFactoryRouter>(_ routerType: FR.Type, callback: FR.CallbackType, action: PresentationAction? = nil, animated: Bool = true) {
        BuilderRouter(routerType).createAndSetup(callback: callback).present(on: associatedViewController, action: action, animated: animated)
    }
}

