//
//  Core.swift
//  DependencyRouter 0.2
//
//  Created by Короткий Виталий on 08.09.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import UIKit


//MARK: FactoryRouter

/// Base protocol for ViewControllerFactory with only information about dependency services (used `Container` as generic type) and default presentation action.
public protocol FactoryRouter: CoreFactoryRouter {
    associatedtype ContainerType
    init(container: ContainerType)
    
    /// Implement if you use only the Core part or you want to specify your default ViewController presentation method. Default: `ShopPresentationAction`.
    func presentationAction() -> PresentationAction
}

/// Internal variant FactoryRouter, used when it is not possible to use the generic type. Warning: Do not inherit or implement directly, use `FactoryRouter`.
public protocol CoreFactoryRouter {
    init?(containerAny: Any)
}

/// Variant FactoryRouter when can created with auto created container.
public protocol AutoFactoryRouter: FactoryRouter {
    init()
}

/// Variant FactoryRouter without container.
public protocol LightFactoryRouter: AutoFactoryRouter { }

/// Container for `AutoFactoryRouter`.
public protocol AutoServiceContainer {
    init()
}

/// Protocol for ViewControllers when support finded and setup VC used InputSource mechanism - find many params in source lists. 
public protocol SourceRouterViewController: CoreSourceRouterViewController {
    associatedtype Factory: FactoryRouter & FactorySupportInputSource
    func createFactoryForSetup() -> Factory
}

/// Core variant SourceRouterViewController without generic type. Not need manual implementation.
public protocol CoreSourceRouterViewController: class {
    func coreCreateFactoryForSetup() -> FactorySupportInputSource
}


/// Container ViewController with childs VC when support router. Example: `UINavigationController: ContainerViewControllerSupportRouter`.
public protocol ContainerViewControllerSupportRouter {
    func findViewController<VCType>() -> VCType?
}

/// General functional in framework
public struct Router { }


//MARK: Presentation

/// Action for Presentation ViewControllers
public protocol PresentationAction {
    /// Performed when need present ViewController. After completion, you need to perform only one call to completeHandler with the result.
    func present(_ viewController: UIViewController, on existingController: UIViewController, animated: Bool, completionHandler: @escaping (PresentationActionResult)->Void)
}

public enum PresentationActionResult {
    case success
    case failure(Error)
}


//MARK: Helpers
extension FactoryRouter {
    /// Simple create ViewController from storyboard.
    public func createViewController<VC: UIViewController>(storyboardName: String, identifier: String?, bundle: Bundle? = nil) -> VC {
        let sb = UIStoryboard(name: storyboardName, bundle: bundle)
        let viewController: UIViewController
        
        if let identifier = identifier {
            viewController = sb.instantiateViewController(withIdentifier: identifier)
        } else {
            viewController = sb.instantiateInitialViewController()!
        }
        
        return viewController as! VC
    }
    
    /// Simple create ViewController from storyboard as instantiate.
    public func createViewController<VC: UIViewController>(storyboardName: String, bundle: Bundle? = nil) -> VC {
        return createViewController(storyboardName: storyboardName, identifier: nil, bundle: bundle)
    }
    
    /// Simple create ViewController from <nibName>.xib file.
    public func createViewControllerFromNib<VC: UIViewController>(_ nibName: String, bundle: Bundle? = nil) -> VC {
        return VC(nibName: nibName, bundle: bundle)
    }
    
    /// Simple create ViewController from <VC>.xib file.
    public func createViewControllerFromNib<VC: UIViewController>(bundle: Bundle? = nil) -> VC {
        return VC(nibName: nil, bundle: bundle)
    }
}


/// Find ViewController in childs view controllers when finded support container (implemented `ContainerViewControllerSupportRouter`)
public func dependencyRouterFindViewController<VCType: UIViewController>(_ viewController: UIViewController) throws -> VCType {
    if let vc = viewController as? VCType {
        return vc
    } else if let vc: VCType = (viewController as? ContainerViewControllerSupportRouter)?.findViewController() {
        return vc
    } else {
        throw DependencyRouterError.viewControllerNotFound(VCType.self)
    }
}


//MARK: - Core Extensions
extension FactoryRouter {
    public init?(containerAny: Any) {
        if let container = containerAny as? ContainerType {
            self.init(container: container)
        } else {
            return nil
        }
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
