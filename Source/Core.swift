//
//  Core.swift
//  DependencyRouter
//
//  Created by Короткий Виталий on 08.09.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import UIKit


//MARK: Base
public protocol FactoryRouter: CoreFactoryRouter {
    associatedtype ContainerType
    init(container: ContainerType)
}

public protocol LightFactoryRouter: FactoryRouter {
    init()
}

public protocol AutoServiceContainer {
    init()
}

public struct EmptyContainer: AutoServiceContainer {
    public init() { }
}


///Wrappers for childViewController support
public protocol ContainerSupportRouter {
    func findViewController<VCType: UIViewController>() -> VCType?
}

//MARK: Core
public protocol CoreFactoryRouter {
    init?(containerAny: Any)
    
    var defaultPresentation: PresentationRouter { get }
}

extension FactoryRouter {
    public init?(containerAny: Any) {
        if let container = containerAny as? ContainerType {
            self.init(container: container)
        } else {
            return nil
        }
    }
    
    public var defaultPresentation: PresentationRouter {
        return ShowPresentationRouter()
    }
}

extension LightFactoryRouter {
    public init?(containerAny: Any) {
        self.init()
    }
    
    public init(container: EmptyContainer) {
        self.init()
    }
}


//MARK: Presentation
public enum PresentationRouterResult {
    case success
    case failure(Error)
}

public protocol PresentationRouter {
    func present(_ viewController: UIViewController, on existingController: UIViewController, animated: Bool, completionHandler: @escaping (PresentationRouterResult)->Void)
}


//MARK: - Helpers

///UIViewController -> VCType with support NavigationController wrapper
public func dependencyRouterFindViewController<VCType: UIViewController>(_ viewController: UIViewController) throws -> VCType {
    if let vc = viewController as? VCType {
        return vc
    } else if let vc: VCType = (viewController as? ContainerSupportRouter)?.findViewController() {
        return vc
    } else {
        throw DependencyRouterError.viewControllerNotFound(VCType.self)
    }
}


public struct PresentationRouterHandler {
    public var presentation: PresentationRouter
    public var viewController: UIViewController
    public var prepareHandlers: [()->Void]
    public var postHandlers: [()->Void]
    
    public init(presentation: PresentationRouter, viewController: UIViewController, prepareHandlers: [()->Void] = [], postHandlers: [()->Void] = []) {
        self.presentation = presentation
        self.viewController = viewController
        self.prepareHandlers = prepareHandlers
        self.postHandlers = postHandlers
    }
    
    public func present(on existingController: UIViewController, animated: Bool = true, completionHandler: ((PresentationRouterResult)->Void)? = nil, assertWhenFailure: Bool = true) {
        for handler in prepareHandlers {
            handler()
        }
        
        presentation.present(viewController, on: existingController, animated: animated) { [postHandlers] (result) in
            switch result {
            case .success:
                for handler in postHandlers {
                    handler()
                }
                
            case .failure(let error):
                if assertWhenFailure {
                    try? DependencyRouterError.tryAsAssert(handler: { throw error })
                }
            }
            
            completionHandler?(result)
        }
    }
}
