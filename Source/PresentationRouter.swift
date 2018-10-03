//
//  PresentationRouter.swift
//  DependencyRouter
//
//  Created by Короткий Виталий on 02/10/2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import UIKit

public struct PresentationRouter {
    
    public init(viewController: UIViewController, actionSource: @autoclosure @escaping ()->PresentationAction) {
        self.store = .viewController(viewController)
        self.actionSource = actionSource
    }
    
    public init(viewController: UIViewController) {
        self.store = .viewController(viewController)
        self.actionSource = { NotPresentationAction() }
    }
    
    public init(error: Error) {
        self.store = .error(error)
        self.actionSource = { NotPresentationAction() }
    }
    
    //MARK: State and Data
    public private(set) var actionSource: ()->PresentationAction
    
    public func viewController() throws -> UIViewController {
        switch store {
        case .viewController(let vc): return vc
        case .error(let error): throw error
        }
    }
    
    public var viewControllerIfReady: UIViewController? {
        switch store {
        case .viewController(let vc): return vc
        case .error: return nil
        }
    }
    
    public var error: Error? {
        switch store {
        case .viewController: return nil
        case .error(let error): return error
        }
    }
    
    //MARK: Setup
    mutating public func setAction(_ actionSource: @autoclosure @escaping ()->PresentationAction) {
        self.actionSource = actionSource
    }
    
    mutating public func addPrepareHandler(_ handler: @escaping ()->Void) {
        prepareHandlers.append(handler)
    }
    
    mutating public func addPostHandler(_ handler: @escaping ()->Void) {
        postHandlers.append(handler)
    }
    
    
    //MARK: Present
    public func present(on existingController: UIViewController, customAction: PresentationAction? = nil, animated: Bool = true, completionHandler: @escaping (PresentationActionResult)->Void) {
        present(on: existingController, customAction: customAction, animated: animated, assertWhenFailure: false, completionHandler: completionHandler)
    }
    
    public func present(on existingController: UIViewController, customAction: PresentationAction? = nil, animated: Bool = true, assertWhenFailure: Bool = true) {
        present(on: existingController, customAction: customAction, animated: animated, assertWhenFailure: assertWhenFailure, completionHandler: nil)
    }
    
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
            handler()
        }
        
        action.present(viewController, on: existingController, animated: animated) { [postHandlers] (result) in
            switch result {
            case .success:
                for handler in postHandlers {
                    handler()
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
    
    
    //MARK: - Private
    private enum Store {
        case viewController(UIViewController)
        case error(Error)
    }
    
    private let store: Store
    private var prepareHandlers: [()->Void] = []
    private var postHandlers: [()->Void] = []
    
}
