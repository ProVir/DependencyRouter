//
//  PresentationRouter.swift
//  DependencyRouter 0.2
//
//  Created by Короткий Виталий on 02/10/2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import UIKit

/// PresentationActions handler
public struct PresentationRouter {
    /**
     Constructor with default action (use lazy created action).
 
     - Parameters:
        - viewController: ViewController for present
        - actionSource: autoclosure with action
     */
    public init(viewController: UIViewController, action actionSource: @autoclosure @escaping ()->PresentationAction) {
        self.store = .viewController(viewController)
        self.actionSource = actionSource
    }
    
    /**
     Constructor without default action.
     
     - Parameter viewController: ViewController for present
     */
    public init(viewController: UIViewController) {
        self.store = .viewController(viewController)
        self.actionSource = { NotPresentationAction() }
    }
    
    /**
     Constructor with error. Usually used in Builder.
     
     - Parameter error: failure result with error always when present
     */
    public init(error: Error) {
        self.store = .error(error)
        self.actionSource = { NotPresentationAction() }
    }
    
    // MARK: State and Data
    /// Autoclosure with action as default
    public private(set) var actionSource: ()->PresentationAction
    
    /// ViewController for present or error
    public func viewController() throws -> UIViewController {
        switch store {
        case .viewController(let vc): return vc
        case .error(let error): throw error
        }
    }
    
    /// ViewController for present if ready (not error)
    public var viewControllerIfReady: UIViewController? {
        switch store {
        case .viewController(let vc): return vc
        case .error: return nil
        }
    }
    
    /// Error if containt
    public var error: Error? {
        switch store {
        case .viewController: return nil
        case .error(let error): return error
        }
    }
    
    // MARK: Setup
    mutating public func setAction(_ actionSource: @autoclosure @escaping ()->PresentationAction) {
        self.actionSource = actionSource
    }
    
    mutating public func addPrepareHandler(_ handler: @escaping (UIViewController)->Void) {
        prepareHandlers.append(handler)
    }
    
    mutating public func addPostHandler(_ handler: @escaping (UIViewController)->Void) {
        postHandlers.append(handler)
    }
    
    // MARK: Present
    /**
     Present ViewController on existing use action and result (success or failure) return in closure.
 
     - Parameters:
        - existingController: the current ViewController on which the created ViewController is presented
        - customAction: (Optional) custom action if need use, else used default action from source (`var actionSource`)
        - animated: present ViewController with animation if true (default)
        - completionHandler: handler with result presented
     */
    public func present(on existingController: UIViewController, customAction: PresentationAction? = nil, animated: Bool = true, completionHandler: @escaping (PresentationActionResult)->Void) {
        present(on: existingController, customAction: customAction, animated: animated, assertWhenFailure: false, completionHandler: completionHandler)
    }
    
    /**
     Present ViewController on existing use action and assertionFailure (usually crash in debug regime) if result is failure.
     
     - Parameters:
        - existingController: the current ViewController on which the created ViewController is presented
        - customAction: (Optional) custom action if need use, else used default action from source (`var actionSource`)
        - animated: present ViewController with animation if true (default)
        - assertWhenFailure: when failure present assertionFailure if true (default)
     */
    public func present(on existingController: UIViewController, customAction: PresentationAction? = nil, animated: Bool = true, assertWhenFailure: Bool = true) {
        present(on: existingController, customAction: customAction, animated: animated, assertWhenFailure: assertWhenFailure, completionHandler: nil)
    }
    
    /**
     Present ViewController on existing use action.
     
     - Parameters:
        - existingController: the current ViewController on which the created ViewController is presented
        - customAction: (Optional) custom action if need use, else used default action from source (`var actionSource`)
        - animated: present ViewController with animation if true (default)
        - assertWhenFailure: when failure present assertionFailure if true
        - completionHandler: (Optional) handler with result presented
     */
    public func present(on existingController: UIViewController, customAction: PresentationAction? = nil, animated: Bool = true, assertWhenFailure: Bool, completionHandler: ((PresentationActionResult)->Void)?) {
        //1. Unwrap VC
        let viewController: UIViewController
        switch self.store {
        case .viewController(let vc):
            viewController = vc
            
        case .error(let error):
            completionHandler?(.failure(error))
            if assertWhenFailure {
                try? DependencyRouterError.tryAsAssert { throw error }
            }
            return
        }
        
        //2. Present VC
        let action = customAction ?? actionSource()
        
        for handler in prepareHandlers {
            handler(viewController)
        }
        
        action.present(viewController, on: existingController, animated: animated) { [postHandlers] (result) in
            switch result {
            case .success:
                for handler in postHandlers {
                    handler(viewController)
                }
                completionHandler?(result)
                
            case .failure(let error):
                completionHandler?(result)
                if assertWhenFailure {
                    try? DependencyRouterError.tryAsAssert(handler: { throw error })
                }
            }
        }
    }
    
    // MARK: - Private
    private enum Store {
        case viewController(UIViewController)
        case error(Error)
    }
    
    private let store: Store
    private var prepareHandlers: [(UIViewController)->Void] = []
    private var postHandlers: [(UIViewController)->Void] = []
}
