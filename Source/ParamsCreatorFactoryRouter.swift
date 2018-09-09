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
}

public protocol ParamsCreatorWithCallbackFactoryRouter: CoreParamsCreatorFactoryRouter, FactoryRouter {
    associatedtype VCType: UIViewController
    associatedtype ParamsType
    associatedtype CallbackType
    
    func createAndSetupViewController(params: ParamsType, callback: CallbackType) -> VCType
}

extension ParamsCreatorFactoryRouter {
    public static func createParams(_ params: ParamsType) -> ParamsType {
        return params
    }
}

extension ParamsCreatorWithCallbackFactoryRouter {
    public static func createParams(_ params: ParamsType) -> ParamsType {
        return params
    }
}


//MARK: - Core
public protocol CoreParamsCreatorFactoryRouter: CoreFactoryRouter {
    func coreCreateAndSetupViewController(params: Any, callbacks: [Any], file: StaticString, line: UInt) -> UIViewController
    var coreNeedCallback: Bool { get }
}

extension ParamsCreatorFactoryRouter {
    public func coreCreateAndSetupViewController(params: Any, callbacks: [Any], file: StaticString = #file, line: UInt = #line) -> UIViewController {
        if let params = params as? ParamsType {
            return createAndSetupViewController(params: params)
        } else {
            FactoryRouterError.paramsInvalidType(type(of: params), required: ParamsType.self).fatalError(file: file, line: line)
        }
    }
    
    public var coreNeedCallback: Bool { return false }
}

extension ParamsCreatorWithCallbackFactoryRouter {
    public func coreCreateAndSetupViewController(params: Any, callbacks: [Any], file: StaticString = #file, line: UInt = #line) -> UIViewController {
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
        
        return createAndSetupViewController(params: s_params, callback: s_callback)
    }
    
    public var coreNeedCallback: Bool { return true }
}





