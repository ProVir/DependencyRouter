//
//  InputSource.swift
//  DependencyRouter
//
//  Created by Короткий Виталий on 17.09.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import Foundation

public protocol BaseFactoryInputSource { }

public protocol FactorySupportInputSource: CoreFactoryRouter {
    func findAndSetup(_ viewController: UIViewController, sourceList: [BaseFactoryInputSource], identifier: String?, sender: Any?) throws
}

public protocol SimplePresentNavigationRouter {
    var associatedViewController: UIViewController? { get }
    var sourceList: [BaseFactoryInputSource] { get }
    
    func performSegue(withIdentifier identifier: String, factory: FactorySupportInputSource, sourceList: [BaseFactoryInputSource], sender: Any?)
}

extension FactorySupportInputSource {
    public func findAndSetupMultiHelper(_ viewController: UIViewController, sourceList: [BaseFactoryInputSource], identifier: String?, sender: Any?, functions: [(UIViewController, [BaseFactoryInputSource], String?, Any?) throws ->Void]) throws {
        var lastError: Error?
        
        for closure in functions {
            do {
                try closure(viewController, sourceList, identifier, sender)
                return
            } catch {
                lastError = error
            }
        }
        
        if let error = lastError {
            throw error
        }
    }
}

//MARK: Auto Setup from segue
extension Router {
    @discardableResult
    public static func prepare(for segue: UIStoryboardSegue, sender: Any?, source: BaseFactoryInputSource?) -> Bool {
        return prepare(for: segue, sender: sender, sourceList: source.map({ [$0] }) ?? [])
    }
    
    @discardableResult
    public static func prepare(for segue: UIStoryboardSegue, sender: Any?, sourceList: [BaseFactoryInputSource]) -> Bool {
        guard let (viewController, factory) = dependencyRouterFindSourceRouterViewController(segue.destination) else {
            return false
        }
        
        DependencyRouterError.tryAsFatalError {
            try factory.findAndSetup(viewController, sourceList: sourceList, identifier: segue.identifier, sender: sender)
        }
        
        return true
    }
    
    @discardableResult
    public static func setupIfSupport(viewController: UIViewController, sourceList: [BaseFactoryInputSource], identifier: String?, sender: Any?, fatalErrorWhenFailure: Bool) -> Bool {
        guard let (viewController, factory) = dependencyRouterFindSourceRouterViewController(viewController) else {
            return false
        }
        
        if fatalErrorWhenFailure {
            DependencyRouterError.tryAsFatalError {
                try factory.findAndSetup(viewController, sourceList: sourceList, identifier: identifier, sender: sender)
            }
        } else {
            do {
                try factory.findAndSetup(viewController, sourceList: sourceList, identifier: identifier, sender: sender)
            } catch {
                return false
            }
        }
        
        return true
    }
}


//MARK: Support Builder
extension BuilderRouterReadySetup where FR: FactoryRouter, FR: FactorySupportInputSource {
    public func setup(source: BaseFactoryInputSource, identifier: String? = nil, sender: Any? = nil) -> BuilderRouterReadyPresent<VC> {
        return setup(sourceList: [source], identifier: identifier, sender: sender)
    }
    
    public func setup(sourceList: [BaseFactoryInputSource], identifier: String? = nil, sender: Any? = nil) -> BuilderRouterReadyPresent<VC> {
        
        let factory = self.factory
        DependencyRouterError.tryAsFatalError {
            try factory.findAndSetup(viewController, sourceList: sourceList, identifier: identifier, sender: sender)
        }
 
        return .init(viewController: viewController, default: factory.presentation())
    }
}

extension BuilderRouterReadyCreate where FR: CreatorFactoryRouter, FR: FactorySupportInputSource {
    public func createAndSetup(source: BaseFactoryInputSource, identifier: String? = nil, sender: Any? = nil) -> BuilderRouterReadyPresent<FR.VCCreateType> {
        return createAndSetup(sourceList: [source], identifier: identifier, sender: sender)
    }
    
    public func createAndSetup(sourceList: [BaseFactoryInputSource], identifier: String? = nil, sender: Any? = nil) -> BuilderRouterReadyPresent<FR.VCCreateType> {
        let factory = self.factory()
        let viewController = factory.createViewController()
        
        DependencyRouterError.tryAsFatalError {
            try factory.findAndSetup(viewController, sourceList: sourceList, identifier: identifier, sender: sender)
        }
        
        return .init(viewController: viewController, default: factory.presentation())
    }
}

//MARK: Helpers
public func dependencyRouterFindSourceRouterViewController(_ viewController: UIViewController) -> (UIViewController & CoreSourceRouterViewController, FactorySupportInputSource)? {
    if let vc = viewController as? UIViewController & CoreSourceRouterViewController {
        return (vc, vc.coreCreateFactoryForSetup())
    } else if let vc: UIViewController & CoreSourceRouterViewController = (viewController as? ViewContainerSupportRouter)?.findViewController() {
        return (vc, vc.coreCreateFactoryForSetup())
    } else {
        return nil
    }
}
