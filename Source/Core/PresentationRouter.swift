//
//  PresentationRouter.swift
//  DependencyRouter 0.3
//
//  Created by Короткий Виталий on 02.10.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import UIKit

/// Assert if use - used as default when require always use own
public struct NotPresentationAction: PresentationAction {
    public init() { }
    
    public func present(_ viewController: UIViewController, on hostController: UIViewController, animated: Bool, completionHandler: @escaping (PresentationActionResult) -> Void) {
        assertionFailure("You need use valid PresentationAction, don't use NotPresentationAction.")
        completionHandler(.failure(DependencyRouterError.notReadyPresentingViewController("need use valid PresentationAction, don't use NotPresentationAction.")))
    }
}

/// PresentationActions handler
public struct PresentationRouter {
    /**
     Constructor with default action (use lazy created action).
 
     - Parameters:
        - viewController: ViewController for present
        - actionSource: autoclosure with action
     */
    public init(viewController: UIViewController, action actionSource: @autoclosure @escaping () -> PresentationAction) {
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
    public private(set) var actionSource: () -> PresentationAction
    
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
    mutating public func setAction(_ actionSource: @autoclosure @escaping () -> PresentationAction) {
        self.actionSource = actionSource
    }
    
    mutating public func addPrepareHandler(_ handler: @escaping (UIViewController) -> Void) {
        prepareHandlers.append(handler)
    }
    
    mutating public func addPostHandler(_ handler: @escaping (UIViewController) -> Void) {
        postHandlers.append(handler)
    }
    
    // MARK: Present
    /**
     Present ViewController on existing use action and result (success or failure) return in closure.
 
     - Parameters:
        - hostController: the current ViewController on which the created ViewController is presented
        - customAction: (Optional) custom action if need use, else used default action from source (`var actionSource`)
        - animated: present ViewController with animation if true (default)
        - completionHandler: handler with result presented
     */
    public func present(on hostController: UIViewController,
                        customAction: PresentationAction? = nil,
                        animated: Bool = true,
                        completionHandler: @escaping (PresentationActionResult) -> Void) {
        present(on: hostController, customAction: customAction, animated: animated, useAssert: false, completionHandler: completionHandler)
    }
    
    /**
     Present ViewController on existing use action and assertionFailure (usually crash in debug regime) if result is failure.
     
     - Parameters:
        - hostController: the current ViewController on which the created ViewController is presented
        - customAction: (Optional) custom action if need use, else used default action from source (`var actionSource`)
        - animated: present ViewController with animation if true (default)
        - useAssert: when failure present assertionFailure if true (default)
     */
    public func present(on hostController: UIViewController,
                        customAction: PresentationAction? = nil,
                        animated: Bool = true,
                        useAssert: Bool = true) {
        present(on: hostController, customAction: customAction, animated: animated, useAssert: useAssert, completionHandler: nil)
    }
    
    /**
     Present ViewController on existing use action.
     
     - Parameters:
        - hostController: the current ViewController on which the created ViewController is presented
        - customAction: (Optional) custom action if need use, else used default action from source (`var actionSource`)
        - animated: present ViewController with animation if true (default)
        - useAssert: when failure present assertionFailure if true
        - completionHandler: (Optional) handler with result presented
     */
    public func present(on hostController: UIViewController,
                        customAction: PresentationAction? = nil,
                        animated: Bool = true,
                        useAssert: Bool,
                        completionHandler: ((PresentationActionResult) -> Void)?) {
        //1. Unwrap VC
        let viewController: UIViewController
        switch self.store {
        case .viewController(let vc):
            viewController = vc
            
        case .error(let error):
            completionHandler?(.failure(error))
            if useAssert {
                try? DependencyRouterError.tryAsAssertionFailure { throw error }
            }
            return
        }
        
        //2. Present VC
        let action = customAction ?? actionSource()
        
        for handler in prepareHandlers {
            handler(viewController)
        }
        
        action.present(viewController, on: hostController, animated: animated) { [postHandlers] (result) in
            switch result {
            case .success:
                for handler in postHandlers {
                    handler(viewController)
                }
                completionHandler?(result)
                
            case .failure(let error):
                completionHandler?(result)
                if useAssert {
                    try? DependencyRouterError.tryAsAssertionFailure(handler: { throw error })
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
    private var prepareHandlers: [(UIViewController) -> Void] = []
    private var postHandlers: [(UIViewController) -> Void] = []
}
