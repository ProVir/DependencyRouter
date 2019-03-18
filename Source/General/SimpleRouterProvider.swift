//
//  SimpleRouterProvider.swift
//  DependencyRouter 0.3
//
//  Created by Короткий Виталий on 09/03/2019.
//  Copyright © 2019 ProVir. All rights reserved.
//

import Foundation

open class SimpleRouterProvider<ServiceFactory>: RouterProvider {
    private let serviceFactory: ServiceFactory

    public init(_ serviceFactory: ServiceFactory) {
        self.serviceFactory = serviceFactory
    }

    open func isSupport<FR>(factoryType: FR.Type) -> Bool where FR : FactoryRouter {
        if serviceFactory is FR.ContainerType {
            return true
        } else if let containerType = FR.ContainerType.self as? CoreRouterServiceContainer.Type {
            return containerType.isSupport(serviceFactoryType: ServiceFactory.self)
        } else {
            return false
        }
    }

    open func factory<FR: FactoryRouter>(_ factoryType: FR.Type) throws -> FR {
        if let factory = factoryIfSupport(factoryType) {
            return factory
        } else {
            throw DependencyRouterError.failureCreateFactory(FR.self)
        }
    }

    private func factoryIfSupport<FR: FactoryRouter>(_ factoryType: FR.Type) -> FR? {
        if let container = serviceFactory as? FR.ContainerType {
            return FR(container: container)
        } else if let containerType = FR.ContainerType.self as? CoreRouterServiceContainer.Type {
            return (containerType.init(serviceFactory, routerProvider: self) as? FR.ContainerType).map { FR(container: $0) }
        } else {
            return nil
        }
    }
}


open class MultiRouterProvider: RouterProvider {
    private let serviceFactories: [Any]

    public init(_ serviceFactories: [Any]) {
        self.serviceFactories = serviceFactories
    }

    open func isSupport<FR>(factoryType: FR.Type) -> Bool where FR : FactoryRouter {
        for serviceFactory in serviceFactories {
            if serviceFactory is FR.ContainerType {
                return true
            } else if let containerType = FR.ContainerType.self as? CoreRouterServiceContainer.Type,
                containerType.isSupport(serviceFactoryType: type(of: serviceFactory)) {
                return true
            }
        }

        return false
    }

    open func factory<FR: FactoryRouter>(_ factoryType: FR.Type) throws -> FR {
        if let factory = factoryIfSupport(factoryType) {
            return factory
        } else {
            throw DependencyRouterError.failureCreateFactory(FR.self)
        }
    }

    private func factoryIfSupport<FR: FactoryRouter>(_ factoryType: FR.Type) -> FR? {
        for serviceFactory in serviceFactories {
            if let container = serviceFactory as? FR.ContainerType {
                return FR(container: container)
            } else if let containerType = FR.ContainerType.self as? CoreRouterServiceContainer.Type,
                let factory = (containerType.init(serviceFactory, routerProvider: self) as? FR.ContainerType).map({ FR(container: $0) }) {
                return factory
            }
        }

        return nil
    }
}
