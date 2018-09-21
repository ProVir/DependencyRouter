//
//  Core.swift
//  DependencyRouter
//
//  Created by Короткий Виталий on 08.09.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import UIKit


//MARK: FactoryRouter
public protocol FactoryRouter: CoreFactoryRouter {
    associatedtype ContainerType
    init(container: ContainerType)
}

public protocol AutoFactoryRouter: FactoryRouter {
    init()
}

public protocol LightFactoryRouter: AutoFactoryRouter { }

public protocol AutoServiceContainer {
    init()
}

public protocol SourceRouterViewController: CoreSourceRouterViewController {
    associatedtype Factory: FactoryRouter & FactorySupportInputSource
    func createFactoryForSetup() -> Factory
}

///Wrappers for childViewController support
public protocol ViewContainerSupportRouter {
    func findViewController<VCType>() -> VCType?
}


public struct Router { }


//MARK: Core
public protocol CoreFactoryRouter {
    init?(containerAny: Any)
    
    func presentation() -> PresentationRouter
}

public protocol CoreSourceRouterViewController: class {
    func coreCreateFactoryForSetup() -> FactorySupportInputSource
}

extension FactoryRouter {
    public init?(containerAny: Any) {
        if let container = containerAny as? ContainerType {
            self.init(container: container)
        } else {
            return nil
        }
    }
    
    public func presentation() -> PresentationRouter {
        return ShowPresentationRouter()
    }
}

extension AutoFactoryRouter where ContainerType: AutoServiceContainer {
    public init() {
        self.init(container: ContainerType())
    }
}

extension AutoFactoryRouter where ContainerType == Void {
    public init() {
        self.init(container: Void())
    }
}

extension LightFactoryRouter {
    public init?(containerAny: Any) {
        self.init()
    }
    
    public init(container: Void) {
        self.init()
    }
}

extension SourceRouterViewController {
    public func coreCreateFactoryForSetup() -> FactorySupportInputSource {
        return createFactoryForSetup()
    }
}

extension SourceRouterViewController where Factory: AutoFactoryRouter {
    public func createFactoryForSetup() -> Factory {
        return Factory()
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
extension FactoryRouter {
    public func createViewController<VC: UIViewController>(storyboardName: String, identifier: String? = nil) -> VC {
        let sb = UIStoryboard(name: storyboardName, bundle: nil)
        let viewController: UIViewController
        
        if let identifier = identifier {
            viewController = sb.instantiateViewController(withIdentifier: identifier)
        } else {
            viewController = sb.instantiateInitialViewController()!
        }
        
        return viewController as! VC
    }
}


///UIViewController -> VCType with support NavigationController wrapper
public func dependencyRouterFindViewController<VCType: UIViewController>(_ viewController: UIViewController) throws -> VCType {
    if let vc = viewController as? VCType {
        return vc
    } else if let vc: VCType = (viewController as? ViewContainerSupportRouter)?.findViewController() {
        return vc
    } else {
        throw DependencyRouterError.viewControllerNotFound(VCType.self)
    }
}

public func dependencyRouterFindViewControllerOrFatalError<VCType: UIViewController>(_ viewController: UIViewController, file: StaticString = #file, line: UInt = #line) -> VCType {
    return DependencyRouterError.tryAsFatalError(file: file, line: line) {
        try dependencyRouterFindViewController(viewController)
    }
}


//MARK: Presentation
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
