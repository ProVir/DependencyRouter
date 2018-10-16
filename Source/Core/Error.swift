//
//  Error.swift
//  DependencyRouter 0.2
//
//  Created by Короткий Виталий on 08.09.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import Foundation

public enum DependencyRouterError: Error {
    case notReadyPresentingViewController(String)   //Parameter: detail text
    case failureSetupViewController
    
    case viewControllerNotFound(Any.Type)   //Parameter: ViewController class

    case inputSourceNotFound(Any)           //Parameter: require InputSource type
    case inputDataInvalidType(String, Any.Type, required: Any.Type) //Parameters: dataName, founded type, required type.
    

    public var description: String {
        switch self {
        case .notReadyPresentingViewController(let detail):
            return "Not ready presenting ViewController: \(detail)"
            
        case .failureSetupViewController:
            return "ViewController setup is failure. Perhaps after a successful configuration you did not set `setupedByRouter = true`"
            
        case .viewControllerNotFound(let vcType):
            return "ViewController with type \(vcType) not found"
            
        case .inputSourceNotFound(let sourceType):
            return "Not found \(sourceType) in input source list"
            
        case .inputDataInvalidType(let dataName, let srcType, required: let requiredType):
            return "\(dataName) (\(srcType) doesn't conform to type \(requiredType)"
        }
    }
    
    /// Fatal error with text from description
    public func fatalError(file: StaticString = #file, line: UInt = #line) -> Never {
        Swift.fatalError(self.description, file: file, line: line)
    }
    
    /// AssertionFailure with text from description
    public func assertionFailure(file: StaticString = #file, line: UInt = #line) {
        Swift.assertionFailure(self.description, file: file, line: line)
    }
}


extension DependencyRouterError {
    public static func tryAsFatalError<R>(file: StaticString = #file, line: UInt = #line, handler: () throws ->R) -> R {
        do {
            return try handler()
        } catch {
            if let error = error as? DependencyRouterError {
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
            if let error = error as? DependencyRouterError {
                error.assertionFailure(file: file, line: line)
            } else {
                Swift.assertionFailure("\(error)" ,file: file, line: line)
            }
            
            throw error
        }
    }
}
