//
//  SimpleFactory.swift
//  DependencyRouter
//
//  Created by Короткий Виталий on 08.09.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import UIKit

public protocol CreatorFactoryRouter: CoreCreatorFactoryRouter, FactoryRouter {
    associatedtype VCCreateType: UIViewController
    func createViewController() -> VCCreateType
}

public protocol BlankCreatorFactoryRouter: CoreBlankCreatorFactoryRouter, FactoryRouter {
    associatedtype VCType: UIViewController
    func createAndSetupViewController() -> VCType
}

public protocol BlankFactoryRouter: CoreBlankFactoryRouter, FactoryRouter {
    associatedtype VCType: UIViewController
    func setupViewController(_ viewController: VCType)
}


//MARK: - Core routing
public protocol CoreCreatorFactoryRouter: CoreFactoryRouter {
    func coreCreateViewController() -> UIViewController
}

public protocol CoreBlankCreatorFactoryRouter: CoreFactoryRouter {
    func coreCreateAndSetupViewController() -> UIViewController
}

public protocol CoreBlankFactoryRouter: CoreFactoryRouter {
    func coreSetupViewController(_ viewController: UIViewController, file: StaticString, line: UInt)
}

extension CreatorFactoryRouter {
    public func coreCreateViewController() -> UIViewController {
        return createViewController()
    }
}

extension BlankCreatorFactoryRouter {
    public func coreCreateAndSetupViewController() -> UIViewController {
        return createAndSetupViewController()
    }
}

extension BlankFactoryRouter {
    public func coreSetupViewController(_ viewController: UIViewController, file: StaticString = #file, line: UInt = #line) {
        let vc: VCType = DependencyRouterError.tryAsFatalError(file: file, line: line) {
            try dependencyRouterFindViewController(viewController)
        }
        
        setupViewController(vc)
    }
}


//MARK: Support Builder
extension BuilderRouterReadyCreate where FR: CreatorFactoryRouter {
    public func create() -> BuilderRouter<FR>.ReadySetup<FR.VCCreateType> {
        let factory = self.factory
        let vc = factory.createViewController()
        return .init(factory: factory, viewController: vc)
    }
}

extension BuilderRouterReadyCreate where FR: BlankCreatorFactoryRouter {
    public func createAndSetup() -> BuilderRouterReadyPresent<FR.VCType>{
        let factory = self.factory
        let vc = factory.createAndSetupViewController()
        return .init(viewController: vc)
    }
}

extension BuilderRouterReadySetup where FR: BlankFactoryRouter {
    public func setup() -> BuilderRouterReadyPresent<VC> {
        factory.coreSetupViewController(viewController)
        return .init(viewController: viewController)
    }
}

extension BuilderRouterReadyCreate where FR: CreatorFactoryRouter, FR: BlankFactoryRouter {
    public func createAndSetup() -> BuilderRouterReadyPresent<FR.VCCreateType>{
        let factory = self.factory
        let vc = factory.createViewController()
        factory.coreSetupViewController(vc)
        return .init(viewController: vc)
    }
}

