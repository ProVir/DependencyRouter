//
//  RouterProvider.swift
//  DependencyRouter 0.3
//
//  Created by Короткий Виталий on 03/03/2019.
//  Copyright © 2019 ProVir. All rights reserved.
//

import Foundation

public protocol RouterServiceContainer {
    associatedtype ServiceFactory
    init(serviceFactory: ServiceFactory, routerProvider: RouterProvider)
}

public protocol RouterProvider: class {
    func isSupport<FR: FactoryRouter>(_ factoryType: FR.Type) -> Bool where FR.ContainerType: RouterServiceContainer
    func createFactory<FR: FactoryRouter>(_ factoryType: FR.Type) throws -> FR where FR.ContainerType: RouterServiceContainer
    func router<FR: FactoryRouter>(_ factoryType: FR.Type) -> BuilderRouter<FR>.ReadyCreate where FR.ContainerType: RouterServiceContainer

    func routerIfSupport<FR: FactoryRouter & PrepareBuilderSupportFactoryRouter, VC: UIViewController>(_ factoryType: FR.Type, use viewController: VC) -> BuilderRouter<FR>.ReadySetup<VC>? where FR.ContainerType: RouterServiceContainer
    func routerIfSupport<FR: FactoryRouter & PrepareBuilderSupportFactoryRouter>(_ factoryType: FR.Type, useSegue segue: UIStoryboardSegue, need identifier: String?) -> BuilderRouter<FR>.ReadySetup<UIViewController>? where FR.ContainerType: RouterServiceContainer
}

extension RouterProvider {
    public func createFactoryOrFatalError<FR: FactoryRouter>(_ factoryType: FR.Type = FR.self) -> FR where FR.ContainerType: RouterServiceContainer {
        return DependencyRouterError.tryAsFatalError { try createFactory(factoryType) }
    }

    public func routerIfSupport<FR: FactoryRouter>(_ factoryType: FR.Type) -> BuilderRouter<FR>.ReadyCreate? where FR.ContainerType: RouterServiceContainer {
        return try? router(factoryType).testFailure()
    }

    public func routerIfSupport<FR: FactoryRouter & PrepareBuilderSupportFactoryRouter>(_ factoryType: FR.Type, useSegue segue: UIStoryboardSegue) -> BuilderRouter<FR>.ReadySetup<UIViewController>? where FR.ContainerType: RouterServiceContainer {
        return routerIfSupport(factoryType, useSegue: segue, need: nil)
    }
}
