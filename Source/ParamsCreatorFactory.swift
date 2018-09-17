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
    func defaultPresentation(params: ParamsType) -> PresentationRouter
}

public protocol ParamsCreatorWithCallbackFactoryRouter: FactoryRouter {
    associatedtype VCType: UIViewController
    associatedtype ParamsType
    associatedtype CallbackType
    
    func createAndSetupViewController(params: ParamsType, callback: CallbackType) -> VCType
    func defaultPresentation(params: ParamsType) -> PresentationRouter
}

public protocol BlankCreatorWithCallbackFactoryRouter: FactoryRouter {
    associatedtype VCType: UIViewController
    associatedtype CallbackType
    
    func createAndSetupViewController(callback: CallbackType) -> VCType
}

//MARK: Helpers
extension ParamsCreatorFactoryRouter {
    public func defaultPresentation(params: ParamsType) -> PresentationRouter {
        return defaultPresentation()
    }
    
    public static func createParams(_ params: ParamsType) -> ParamsType {
        return params
    }
}

extension ParamsCreatorWithCallbackFactoryRouter {
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

extension BlankCreatorWithCallbackFactoryRouter {
    public static func useCallback(_ callback: CallbackType) -> CallbackType {
        return callback
    }
}



//MARK: Support Builder
extension BuilderRouterReadyCreate where FR: ParamsCreatorFactoryRouter {
    public func createAndSetup(params: FR.ParamsType) -> BuilderRouterReadyPresent<FR.VCType> {
        let factory = self.factory
        let vc = factory.createAndSetupViewController(params: params)
        return .init(viewController: vc, default: factory.defaultPresentation(params: params))
    }
}

extension BuilderRouterReadyCreate where FR: ParamsCreatorWithCallbackFactoryRouter {
    public func createAndSetup(params: FR.ParamsType, callback: FR.CallbackType) -> BuilderRouterReadyPresent<FR.VCType> {
        let factory = self.factory
        let vc = factory.createAndSetupViewController(params: params, callback: callback)
        return .init(viewController: vc, default: factory.defaultPresentation(params: params))
    }
}

extension BuilderRouterReadyCreate where FR: BlankCreatorWithCallbackFactoryRouter {
    public func createAndSetup(callback: FR.CallbackType) -> BuilderRouterReadyPresent<FR.VCType> {
        let factory = self.factory
        let vc = factory.createAndSetupViewController(callback: callback)
        return .init(viewController: vc, default: factory.defaultPresentation())
    }
}



