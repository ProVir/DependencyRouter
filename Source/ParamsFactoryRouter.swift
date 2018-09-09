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
}

public protocol ParamsWithCallbackFactoryRouter: CoreParamsFactoryRouter, FactoryRouter {
    associatedtype VCType: UIViewController
    associatedtype ParamsType
    associatedtype CallbackType
    
    func setupViewController(_ viewController: VCType, params: ParamsType, callback: CallbackType)
}

extension ParamsFactoryRouter {
    public static func createParams(_ params: ParamsType) -> ParamsType {
        return params
    }
}

extension ParamsWithCallbackFactoryRouter {
    public static func createParams(_ params: ParamsType) -> ParamsType {
        return params
    }
}


//MARK: - Core
public protocol CoreParamsFactoryRouter: CoreFactoryRouter {
    func coreSetupViewController(_ viewController: UIViewController, params: Any, callbacks: [Any], file: StaticString, line: UInt)
    var coreNeedCallback: Bool { get }
}

extension ParamsFactoryRouter {
    public func coreSetupViewController(_ viewController: UIViewController, params: Any, callbacks: [Any], file: StaticString = #file, line: UInt = #line) {
        let vc: VCType = FactoryRouterError.tryAsFatalError(file: file, line: line) {
            try factoryRouterFindViewController(viewController)
        }
        
        if let params = params as? ParamsType {
            setupViewController(vc, params: params)
        } else {
            FactoryRouterError.paramsInvalidType(type(of: params), required: ParamsType.self).fatalError(file: file, line: line)
        }
    }
    
    public var coreNeedCallback: Bool { return false }
}

extension ParamsWithCallbackFactoryRouter {
    public func coreSetupViewController(_ viewController: UIViewController, params: Any, callbacks: [Any], file: StaticString = #file, line: UInt = #line) {
        let vc: VCType = FactoryRouterError.tryAsFatalError(file: file, line: line) {
            try factoryRouterFindViewController(viewController)
        }
        
        guard let s_params = params as? ParamsType else {
            FactoryRouterError.paramsInvalidType(type(of: params), required: ParamsType.self).fatalError(file: file, line: line)
        }
        
        var callback: CallbackType?
        for cb in callbacks {
            if let cb = cb as? CallbackType {
                callback = cb
                break
            }
        }
        
        guard let s_callback = callback else {
            FactoryRouterError.callbackNotFound(CallbackType.self).fatalError(file: file, line: line)
        }
        
        setupViewController(vc, params: s_params, callback: s_callback)
    }
    
    public var coreNeedCallback: Bool { return true }
}

