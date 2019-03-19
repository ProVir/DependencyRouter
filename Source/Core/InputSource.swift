//
//  InputSource.swift
//  DependencyRouter 0.3
//
//  Created by Короткий Виталий on 17.09.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import UIKit

/// InputSource base protocol for Factory
public protocol BaseFactoryInputSource { }

/// Protocol for Factories which can setup ViewController used InputSource
public protocol FactorySupportInputSource: CoreFactoryRouter {
    func findAndSetup(_ viewController: UIViewController, sourceList: [BaseFactoryInputSource], identifier: String?, sender: Any?) throws
}

/// Protocol for NavigationRouter with contains `simplePresent()` or `performSegue()` functions for many factories types as a simple alternative to the builder for special cases. `associatedViewController` used as existingViewController for present, `sourceList` used only of some functions.
public protocol SimplePresentNavigationRouter {
    var associatedViewController: UIViewController? { get }
    var sourceList: [BaseFactoryInputSource] { get }
    
    /// Support use many factories with perform segue and InputSources. Also used for simple `performSegue()` functions for many factories types
    func performSegue(withIdentifier identifier: String, factory: FactorySupportInputSource, sourceList: [BaseFactoryInputSource], sender: Any?)
}

extension FactorySupportInputSource {
    /// Find and setup helper when used many factories supported InputSource and need implementation `findAndSetup()` function. Parameter `functions` - array `findAndSetup()` functions in factories.
    public func findAndSetupMultiHelper(_ viewController: UIViewController, sourceList: [BaseFactoryInputSource], identifier: String?, sender: Any?, functions: [(UIViewController, [BaseFactoryInputSource], String?, Any?) throws -> Void]) throws {
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

// MARK: Auto Setup from segue
extension Router {
    /// Setup ViewController from segue if support used InputSource. Fatal error when `findAndSetup` returned error.
    @discardableResult
    public static func prepare(for segue: UIStoryboardSegue, sender: Any?, source: BaseFactoryInputSource?) -> Bool {
        return prepare(for: segue, sender: sender, sourceList: source.map({ [$0] }) ?? [])
    }
    
    /// Setup ViewController from segue if support used array InputSource. Fatal error when `findAndSetup` returned error.
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
    
    /// Setup ViewController from segue if support used array InputSource.
    @discardableResult
    public static func tryPrepare(for segue: UIStoryboardSegue, sender: Any?, sourceList: [BaseFactoryInputSource]) throws -> Bool {
        guard let (viewController, factory) = dependencyRouterFindSourceRouterViewController(segue.destination) else {
            return false
        }
        
        try factory.findAndSetup(viewController, sourceList: sourceList, identifier: segue.identifier, sender: sender)
        return true
    }
    
    /// Setup ViewController if support used array InputSource.
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
    
    /// Setup ViewController if support used array InputSource.
    @discardableResult
    public static func trySetupIfSupport(viewController: UIViewController, sourceList: [BaseFactoryInputSource], identifier: String?, sender: Any?) throws -> Bool {
        guard let (viewController, factory) = dependencyRouterFindSourceRouterViewController(viewController) else {
            return false
        }
        
        try factory.findAndSetup(viewController, sourceList: sourceList, identifier: identifier, sender: sender)
        return true
    }
}

// MARK: Support Builder
extension BuilderRouterReadySetup where FR: FactoryRouter, FR: FactorySupportInputSource {
    /// Builder step: setup used InputSource
    public func setup(source: BaseFactoryInputSource, identifier: String? = nil, sender: Any? = nil) -> BuilderRouterReadyPresent<VC> {
        return setup(sourceList: [source], identifier: identifier, sender: sender)
    }
    
    /// Builder step: setup used array InputSource
    public func setup(sourceList: [BaseFactoryInputSource], identifier: String? = nil, sender: Any? = nil) -> BuilderRouterReadyPresent<VC> {
        do {
            let factory = try self.factory()
            let vc = try viewController()
            try factory.findAndSetup(findedForSetupViewController() ?? vc, sourceList: sourceList, identifier: identifier, sender: sender)
            return .init(viewController: vc, default: factory.presentationAction())
        } catch {
            return .init(error: error)
        }
    }
}

// MARK: Helpers
/// Helper function: find ViewController with support InputSource setup and create factory for use next
public func dependencyRouterFindSourceRouterViewController(_ viewController: UIViewController) -> (UIViewController & CoreSourceRouterViewController, FactorySupportInputSource)? {
    if let vc = viewController as? UIViewController & CoreSourceRouterViewController {
        return (vc, vc.coreCreateFactoryForSetup())
    } else if let vc: UIViewController & CoreSourceRouterViewController = (viewController as? ContainerViewControllerSupportRouter)?.findViewController() {
        return (vc, vc.coreCreateFactoryForSetup())
    } else {
        return nil
    }
}
