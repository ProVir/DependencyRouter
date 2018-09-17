//
//  ParamsCreatorFactoryRouter.swift
//  DependencyRouter
//
//  Created by Короткий Виталий on 09.09.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import UIKit

public protocol ParamsCreatorFactoryRouter: CoreParamsCreatorFactoryRouter, FactoryRouter {
    associatedtype VCType: UIViewController
    associatedtype ParamsType
    
    func createAndSetupViewController(params: ParamsType) -> VCType
    func defaultPresentation(params: ParamsType) -> PresentationRouter
}

public protocol ParamsCreatorWithCallbackFactoryRouter: CoreParamsCreatorFactoryRouter, FactoryRouter {
    associatedtype VCType: UIViewController
    associatedtype ParamsType
    associatedtype CallbackType
    
    func createAndSetupViewController(params: ParamsType, callback: CallbackType) -> VCType
    func defaultPresentation(params: ParamsType) -> PresentationRouter
}

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
}


//MARK: - Core
public protocol CoreParamsCreatorFactoryRouter: CoreFactoryRouter {
    var coreNeedCallback: Bool { get }
    
    func coreCreateAndSetupViewController(params: Any, callbacks: [Any], file: StaticString, line: UInt) -> UIViewController
    func coreDefaultPresentation(params: Any) -> PresentationRouter
}

extension ParamsCreatorFactoryRouter {
    public var coreNeedCallback: Bool { return false }
    
    public func coreCreateAndSetupViewController(params: Any, callbacks: [Any], file: StaticString = #file, line: UInt = #line) -> UIViewController {
        if let params = params as? ParamsType {
            return createAndSetupViewController(params: params)
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

extension ParamsCreatorWithCallbackFactoryRouter {
    public var coreNeedCallback: Bool { return true }
    
    public func coreCreateAndSetupViewController(params: Any, callbacks: [Any], file: StaticString = #file, line: UInt = #line) -> UIViewController {
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
        
        return createAndSetupViewController(params: s_params, callback: s_callback)
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



