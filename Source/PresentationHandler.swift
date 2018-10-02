//
//  PresentationHandler.swift
//  DependencyRouter
//
//  Created by Короткий Виталий on 02/10/2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import UIKit

public struct PresentationHandler {
    
    public init(viewController: UIViewController, presentationSource: @autoclosure @escaping ()->PresentationRouter) {
        self.store = .viewController(viewController)
        self.presentationSource = presentationSource
    }
    
    public init(viewController: UIViewController) {
        self.store = .viewController(viewController)
        self.presentationSource = { NotPresentationRouter() }
    }
    
    public init(error: Error) {
        self.store = .error(error)
        self.presentationSource = { NotPresentationRouter() }
    }
    
    //MARK: State and Data
    public private(set) var presentationSource: ()->PresentationRouter
    
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
    mutating public func setPresentationRouter(_ presentationSource: @autoclosure @escaping ()->PresentationRouter) {
        self.presentationSource = presentationSource
    }
    
    mutating public func addPrepareHandler(_ handler: @escaping ()->Void) {
        prepareHandlers.append(handler)
    }
    
    mutating public func addPostHandler(_ handler: @escaping ()->Void) {
        postHandlers.append(handler)
    }
    
    
    //MARK: Present
    public func present(on existingController: UIViewController, customPresentation: PresentationRouter? = nil, animated: Bool = true, completionHandler: @escaping (PresentationRouterResult)->Void) {
        present(on: existingController, customPresentation: customPresentation, animated: animated, assertWhenFailure: false, completionHandler: completionHandler)
    }
    
    public func present(on existingController: UIViewController, customPresentation: PresentationRouter? = nil, animated: Bool = true, assertWhenFailure: Bool = true) {
        present(on: existingController, customPresentation: customPresentation, animated: animated, assertWhenFailure: assertWhenFailure, completionHandler: nil)
    }
    
    public func present(on existingController: UIViewController, customPresentation: PresentationRouter? = nil, animated: Bool = true, assertWhenFailure: Bool, completionHandler: ((PresentationRouterResult)->Void)?) {
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
        let presentation = customPresentation ?? presentationSource()
        
        for handler in prepareHandlers {
            handler()
        }
        
        presentation.present(viewController, on: existingController, animated: animated) { [postHandlers] (result) in
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
