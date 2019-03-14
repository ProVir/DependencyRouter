//
//  SimpleRouterProvider.swift
//  DependencyRouter 0.3
//
//  Created by Vitalii Korotkii on 09/03/2019.
//  Copyright © 2019 ProVir. All rights reserved.
//

import Foundation

open class SimpleRouterProvider<ServiceFactory>: InternalSimpleRouterProvider {
    private let serviceFactory: ServiceFactory

    public init(_ serviceFactory: ServiceFactory) {
        self.serviceFactory = serviceFactory
    }

    fileprivate override func findServiceFactory<FR: FactoryRouter>(_ factoryType: FR.Type) -> FR.ContainerType.ServiceFactory? where FR.ContainerType: RouterServiceContainer {
        return serviceFactory as? FR.ContainerType.ServiceFactory
    }
}

open class MultiRouterProvider: InternalSimpleRouterProvider {
    private let serviceFactories: [Any]

    public init(_ serviceFactories: [Any]) {
        self.serviceFactories = serviceFactories
    }

    fileprivate override func findServiceFactory<FR: FactoryRouter>(_ factoryType: FR.Type) -> FR.ContainerType.ServiceFactory? where FR.ContainerType: RouterServiceContainer {
        for factory in serviceFactories {
            if let factory = factory as? FR.ContainerType.ServiceFactory {
                return factory
            }
        }
        return nil
    }
}

open class InternalSimpleRouterProvider: RouterProvider {
    fileprivate func findServiceFactory<FR: FactoryRouter>(_ factoryType: FR.Type) -> FR.ContainerType.ServiceFactory? where FR.ContainerType: RouterServiceContainer {
        fatalError("Not support InternalSimpleRouterProvider, need use SimpleRouterProvider or MultiRouterProvider.")
    }

    public func isSupport<FR: FactoryRouter>(_ factoryType: FR.Type) -> Bool where FR.ContainerType: RouterServiceContainer {
        return findServiceFactory(factoryType) != nil
    }

    public func factory<FR: FactoryRouter>(_ factoryType: FR.Type) throws -> FR where FR.ContainerType: RouterServiceContainer {
        if let factory = findServiceFactory(factoryType) {
            return FR.init(container: .init(factory, routerProvider: self))
        } else {
           throw DependencyRouterError.serviceFactoryNotFound(FR.ContainerType.ServiceFactory.self)
        }
    }
}
