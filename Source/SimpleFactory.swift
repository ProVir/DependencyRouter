//
//  SimpleFactory.swift
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

public protocol BlankCreatorFactoryRouter: FactoryRouter {
    associatedtype VCType: UIViewController
    func createAndSetupViewController() -> VCType
}

public protocol BlankFactoryRouter: FactoryRouter {
    associatedtype VCType: UIViewController
    func setupViewController(_ viewController: VCType)
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
        return .init(viewController: vc, default: factory.defaultPresentation())
    }
}

extension BuilderRouterReadySetup where FR: BlankFactoryRouter {
    public func setup() -> BuilderRouterReadyPresent<VC> {
        let factory = self.factory
        let findedViewController: FR.VCType = dependencyRouterFindViewControllerOrFatalError(viewController)
        
        factory.setupViewController(findedViewController)
        return .init(viewController: viewController, default: factory.defaultPresentation())
    }
}

extension BuilderRouterReadyCreate where FR: CreatorFactoryRouter, FR: BlankFactoryRouter {
    public func createAndSetup() -> BuilderRouterReadyPresent<FR.VCCreateType>{
        let factory = self.factory
        let viewController = factory.createViewController()
        let findedViewController: FR.VCType = dependencyRouterFindViewControllerOrFatalError(viewController)
        
        factory.setupViewController(findedViewController)
        return .init(viewController: viewController, default: factory.defaultPresentation())
    }
}

