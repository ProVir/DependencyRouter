//
//  BlankFactory.swift
//  DependencyRouter
//
//  Created by Короткий Виталий on 08.09.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import UIKit

public protocol CreatorFactoryRouter: FactoryRouter {
    associatedtype VCCreateType: UIViewController
    func createViewController() -> VCCreateType
}

public protocol BlankFactoryRouter: FactoryRouter, FactorySupportInputSource {
    associatedtype VCType: UIViewController
    func setupViewController(_ viewController: VCType)
}

public protocol BlankCreatorFactoryRouter: FactoryRouter {
    associatedtype VCType: UIViewController
    func createAndSetupViewController() -> VCType
}

public typealias AutoCreatorFactoryRouter       = AutoFactoryRouter & CreatorFactoryRouter
public typealias AutoBlankFactoryRouter         = AutoFactoryRouter & BlankFactoryRouter
public typealias AutoBlankCreatorFactoryRouter  = AutoFactoryRouter & BlankCreatorFactoryRouter

public typealias LightCreatorFactoryRouter       = LightFactoryRouter & CreatorFactoryRouter
public typealias LightBlankFactoryRouter         = LightFactoryRouter & BlankFactoryRouter
public typealias LightBlankCreatorFactoryRouter  = LightFactoryRouter & BlankCreatorFactoryRouter


//MARK: Support Builder
extension BuilderRouterReadyCreate where FR: CreatorFactoryRouter {
    public func create() -> BuilderRouter<FR>.ReadySetup<FR.VCCreateType> {
        let factory = self.factory()
        let vc = factory.createViewController()
        return .init(factory: factory, viewController: vc)
    }
}

extension BuilderRouterReadySetup where FR: BlankFactoryRouter {
    public func setup() -> BuilderRouterReadyPresent<VC> {
        do {
            let findedViewController: FR.VCType = try dependencyRouterFindViewController(viewController)
            let factory = self.factory()
            
            factory.setupViewController(findedViewController)
            return .init(viewController: viewController, default: factory.presentationAction())
        } catch {
            return .init(error: error)
        }
    }
}

extension BuilderRouterReadyCreate where FR: BlankCreatorFactoryRouter {
    public func createAndSetup() -> BuilderRouterReadyPresent<FR.VCType>{
        let factory = self.factory()
        let vc = factory.createAndSetupViewController()
        return .init(viewController: vc, default: factory.presentationAction())
    }
}

extension BuilderRouterReadyCreate where FR: CreatorFactoryRouter, FR: BlankFactoryRouter {
    public func createAndSetup() -> BuilderRouterReadyPresent<FR.VCCreateType>{
        do {
            let factory = self.factory()
            let viewController = factory.createViewController()
            let findedViewController: FR.VCType = try dependencyRouterFindViewController(viewController)
            
            factory.setupViewController(findedViewController)
            return .init(viewController: viewController, default: factory.presentationAction())
        } catch {
            return .init(error: error)
        }
    }
}

//MARK: Support Present NavigationRouter
extension SimplePresentNavigationRouter {
    public func simplePresent<FR: AutoCreatorFactoryRouter & BlankFactoryRouter>(_ routerType: FR.Type, action: PresentationAction? = nil, animated: Bool = true) {
        if let viewController = associatedViewController {
            BuilderRouter(routerType).createAndSetup().present(on: viewController, action: action, animated: animated)
        }
    }
    
    public func simplePresent<FR: AutoBlankCreatorFactoryRouter>(_ routerType: FR.Type, action: PresentationAction? = nil, animated: Bool = true) {
        if let viewController = associatedViewController {
            BuilderRouter(routerType).createAndSetup().present(on: viewController, action: action, animated: animated)
        }
    }
    
    public func performSegue<FR: BlankFactoryRouter>(withIdentifier identifier: String, factory: FR, sender: Any? = nil) {
        performSegue(withIdentifier: identifier, factory: factory, sourceList: [], sender: sender)
    }
}

//MARK: Support InputSource
extension BlankFactoryRouter {
    public func findAndSetup(_ viewController: UIViewController, sourceList: [BaseFactoryInputSource], identifier: String?, sender: Any?) throws {
        try coreFindAndSetupBlank(viewController, sourceList: sourceList, identifier: identifier, sender: sender)
    }
    
    public func coreFindAndSetupBlank(_ viewController: UIViewController, sourceList: [BaseFactoryInputSource], identifier: String?, sender: Any?) throws {
        setupViewController(try dependencyRouterFindViewController(viewController))
    }
}

