//
//  FactoryRouterError.swift
//  DependencyRouter
//
//  Created by Короткий Виталий on 08.09.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import Foundation

extension FactoryRouterError {
    public static func tryAsFatalError<R>(file: StaticString = #file, line: UInt = #line, handler: () throws ->R) -> R {
        do {
            return try handler()
        } catch {
            if let error = error as? FactoryRouterError {
                error.fatalError(file: file, line: line)
            } else {
                Swift.fatalError("\(error)" ,file: file, line: line)
            }
        }
    }
    
    public static func tryAsAssert<R>(file: StaticString = #file, line: UInt = #line, handler: () throws ->R) throws -> R {
        do {
            return try handler()
        } catch {
            if let error = error as? FactoryRouterError {
                error.assertionFailure(file: file, line: line)
            } else {
                Swift.assertionFailure("\(error)" ,file: file, line: line)
            }
            
            throw error
        }
    }
}

public enum FactoryRouterError: Error {
//    case viewControllerNotFactoryRouterSupporting
    case viewControllerNotFound(UIViewController.Type)
    
//    case factoryRouterNotFound
//    case factoryRouterInvalidType(CoreFactoryRouter.Type)
    
    case paramsInvalidType(Any.Type, required: Any.Type)
    case paramsNotFound
    case callbackNotFound(Any.Type)
    
//    case containerInvalidType(Any.Type, routerType: CoreFactoryRouter.Type)
//    case stateRestoreContainerNotFound(type: Any.Type, identifier:String?)
    
    
    public var description: String {
        switch self {
//        case .viewControllerNotFactoryRouterSupporting:
//            return "ViewController doesn't conform to FactoryRouterSupporting"

        case .viewControllerNotFound(let vcType):
            return "ViewController with type \(vcType) not found"

//        case .factoryRouterNotFound:
//            return "Not found ViewController conformed to FactoryRouterSupporting"
//
//        case .factoryRouterInvalidType(let routerType):
//            return "Invalid factory router type \(routerType)"
            
        case .paramsInvalidType(let srcType, required: let requiredType):
            return "Params (\(srcType) doesn't conform to type \(requiredType)"
            
        case .paramsNotFound:
            return "Params not found"
            
        case .callbackNotFound(let cbType):
            return "Callback type \(cbType) don't finded"
            
//        case .containerInvalidType(let providerType, routerType: let routerType):
//            return "Invalid container type \(providerType) for FactoryRouter type \(routerType)"
//
//        case .stateRestoreContainerNotFound(type: let type, identifier: let identifier):
//            return "Not found container with type \(type) for state restore with identifier = \"\(identifier ?? "nil")\""
        }
    }
    
    public func fatalError(file: StaticString = #file, line: UInt = #line) -> Never {
        Swift.fatalError(self.description, file: file, line: line)
    }
    
    public func assertionFailure(file: StaticString = #file, line: UInt = #line) {
        Swift.assertionFailure(self.description, file: file, line: line)
    }
}
