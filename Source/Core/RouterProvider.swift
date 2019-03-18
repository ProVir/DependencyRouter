//
//  RouterProvider.swift
//  DependencyRouter 0.3
//
//  Created by Короткий Виталий on 03/03/2019.
//  Copyright © 2019 ProVir. All rights reserved.
//

import Foundation

/// Provider for create FactoryRouter with private containers
public protocol RouterProvider: class {
    func isSupport<FR: FactoryRouter>(factoryType: FR.Type) -> Bool
    func factory<FR: FactoryRouter>(_ factoryType: FR.Type) throws -> FR
}

extension RouterProvider {
    public func factoryOrFatalError<FR: FactoryRouter>(_ factoryType: FR.Type = FR.self) -> FR {
        return DependencyRouterError.tryAsFatalError { try factory(factoryType) }
    }
}


// MARK: ServiceContainer
public protocol RouterServiceContainer: CoreRouterServiceContainer {
    associatedtype ServiceFactory
    init(_ serviceFactory: ServiceFactory, routerProvider: RouterProvider)
}

public protocol CoreRouterServiceContainer {
    init?(_ serviceFactory: Any, routerProvider: RouterProvider)
    static func isSupport(serviceFactoryType: Any.Type) -> Bool
}

extension RouterServiceContainer {
    public init?(_ serviceFactory: Any, routerProvider: RouterProvider) {
        if let factory = serviceFactory as? ServiceFactory {
            self.init(factory, routerProvider: routerProvider)
        } else {
            return nil
        }
    }

    static func isSupport(serviceFactoryType: Any.Type) -> Bool {
        return serviceFactoryType is ServiceFactory.Type
    }
}
