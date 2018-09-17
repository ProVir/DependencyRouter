//
//  ParamsFactoryRouter.swift
//  DependencyRouter
//
//  Created by Короткий Виталий on 08.09.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import UIKit

public protocol ParamsFactoryRouter: CoreParamsFactoryRouter, FactoryRouter {
    associatedtype VCType: UIViewController
    associatedtype ParamsType
    
    func setupViewController(_ viewController: VCType, params: ParamsType)
    func defaultPresentation(params: ParamsType) -> PresentationRouter
}

public protocol ParamsWithCallbackFactoryRouter: CoreParamsFactoryRouter, FactoryRouter {
    associatedtype VCType: UIViewController
    associatedtype ParamsType
    associatedtype CallbackType
    
    func setupViewController(_ viewController: VCType, params: ParamsType, callback: CallbackType)
    func defaultPresentation(params: ParamsType) -> PresentationRouter
}

extension ParamsFactoryRouter {
    public func defaultPresentation(params: ParamsType) -> PresentationRouter {
        return defaultPresentation()
    }
    
    public static func createParams(_ params: ParamsType) -> ParamsType {
        return params
    }
}

extension ParamsWithCallbackFactoryRouter {
    public func defaultPresentation(params: ParamsType) -> PresentationRouter {
        return defaultPresentation()
    }
    
    public static func createParams(_ params: ParamsType) -> ParamsType {
        return params
    }
}


//MARK: - Core
public protocol CoreParamsFactoryRouter: CoreFactoryRouter {
    var coreNeedCallback: Bool { get }
    
    func coreSetupViewController(_ viewController: UIViewController, params: Any, callbacks: [Any], file: StaticString, line: UInt)
    func coreDefaultPresentation(params: Any) -> PresentationRouter
}

extension ParamsFactoryRouter {
    public var coreNeedCallback: Bool { return false }
    
    public func coreSetupViewController(_ viewController: UIViewController, params: Any, callbacks: [Any], file: StaticString = #file, line: UInt = #line) {
        let vc: VCType = DependencyRouterError.tryAsFatalError(file: file, line: line) {
            try dependencyRouterFindViewController(viewController)
        }
        
        if let params = params as? ParamsType {
            setupViewController(vc, params: params)
        } else {
            DependencyRouterError.paramsInvalidType(type(of: params), required: ParamsType.self).fatalError(file: file, line: line)
        }
    }
    
    func coreDefaultPresentation(params: Any) -> PresentationRouter {
        if let params = params as? ParamsType {
            return defaultPresentation(params: params)
        } else {
            return defaultPresentation()
        }
    }
}

extension ParamsWithCallbackFactoryRouter {
    public var coreNeedCallback: Bool { return true }
    
    public func coreSetupViewController(_ viewController: UIViewController, params: Any, callbacks: [Any], file: StaticString = #file, line: UInt = #line) {
        let vc: VCType = DependencyRouterError.tryAsFatalError(file: file, line: line) {
            try dependencyRouterFindViewController(viewController)
        }
        
        guard let s_params = params as? ParamsType else {
            DependencyRouterError.paramsInvalidType(type(of: params), required: ParamsType.self).fatalError(file: file, line: line)
        }
        
        var callback: CallbackType?
        for cb in callbacks {
            if let cb = cb as? CallbackType {
                callback = cb
                break
            }
        }
        
        guard let s_callback = callback else {
            DependencyRouterError.callbackNotFound(CallbackType.self).fatalError(file: file, line: line)
        }
        
        setupViewController(vc, params: s_params, callback: s_callback)
    }
    
    func coreDefaultPresentation(params: Any) -> PresentationRouter {
        if let params = params as? ParamsType {
            return defaultPresentation(params: params)
        } else {
            return defaultPresentation()
        }
    }
}


//MARK: Support Builder
extension BuilderRouterReadySetup where FR: ParamsFactoryRouter {
    public func setup(params: FR.ParamsType) -> BuilderRouterReadyPresent<VC> {
        let factory = self.factory
        factory.coreSetupViewController(viewController, params: params, callbacks: [])
        return .init(viewController: viewController, default: factory.defaultPresentation(params: params))
    }
}

extension BuilderRouterReadySetup where FR: ParamsWithCallbackFactoryRouter {
    public func setup(params: FR.ParamsType, callback: FR.CallbackType) -> BuilderRouterReadyPresent<VC> {
        let factory = self.factory
        factory.coreSetupViewController(viewController, params: params, callbacks: [callback])
        return .init(viewController: viewController, default: factory.defaultPresentation(params: params))
    }
}

extension BuilderRouterReadyCreate where FR: CreatorFactoryRouter, FR: ParamsFactoryRouter {
    public func createAndSetup(params: FR.ParamsType) -> BuilderRouterReadyPresent<FR.VCCreateType> {
        let factory = self.factory
        let vc = factory.createViewController()
        factory.coreSetupViewController(vc, params: params, callbacks: [])
        return .init(viewController: vc, default: factory.defaultPresentation(params: params))
    }
}

extension BuilderRouterReadyCreate where FR: CreatorFactoryRouter, FR: ParamsWithCallbackFactoryRouter {
    public func createAndSetup(params: FR.ParamsType, callback: FR.CallbackType) -> BuilderRouterReadyPresent<FR.VCCreateType> {
        let factory = self.factory
        let vc = factory.createViewController()
        factory.coreSetupViewController(vc, params: params, callbacks: [callback])
        return .init(viewController: vc, default: factory.defaultPresentation(params: params))
    }
}



