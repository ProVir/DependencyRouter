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

    public init(serviceFactory: ServiceFactory) {
        self.serviceFactory = serviceFactory
    }

    fileprivate override func findServiceFactory<FR: FactoryRouter>(_ factoryType: FR.Type) -> FR.ContainerType.ServiceFactory? where FR.ContainerType: RouterServiceContainer {
        return serviceFactory as? FR.ContainerType.ServiceFactory
    }
}

open class MultiRouterProvider: InternalSimpleRouterProvider {
    private let serviceFactories: [Any]

    public init(serviceFactories: [Any]) {
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

    public func createFactory<FR: FactoryRouter>(_ factoryType: FR.Type) throws -> FR where FR.ContainerType: RouterServiceContainer {
        if let factory = findServiceFactory(factoryType) {
            return FR.init(container: .init(serviceFactory: factory, routerProvider: self))
        } else {
           throw DependencyRouterError.serviceFactoryNotFound(FR.ContainerType.ServiceFactory.self)
        }
    }

    public func router<FR: FactoryRouter>(_ factoryType: FR.Type) -> BuilderRouter<FR>.ReadyCreate where FR.ContainerType: RouterServiceContainer {
        if let factory = findServiceFactory(factoryType) {
            return BuilderRouter(FR.self).setContainer(lazy: .init(serviceFactory: factory, routerProvider: self))
        } else {
            return .init(error: DependencyRouterError.serviceFactoryNotFound(FR.ContainerType.ServiceFactory.self))
        }
    }

    public func routerIfSupport<FR: FactoryRouter & PrepareBuilderSupportFactoryRouter, VC: UIViewController>(_ factoryType: FR.Type, use viewController: VC) -> BuilderRouter<FR>.ReadySetup<VC>? where FR.ContainerType: RouterServiceContainer {
        if let factory = findServiceFactory(factoryType) {
            return BuilderRouter(FR.self).builderIfSupport(use: viewController)?
                .setContainer(lazy: .init(serviceFactory: factory, routerProvider: self))
        } else {
            return .init(error: DependencyRouterError.serviceFactoryNotFound(FR.ContainerType.ServiceFactory.self))
        }
    }

    public func routerIfSupport<FR: FactoryRouter & PrepareBuilderSupportFactoryRouter>(_ factoryType: FR.Type, useSegue segue: UIStoryboardSegue, need identifier: String?) -> BuilderRouter<FR>.ReadySetup<UIViewController>? where FR.ContainerType: RouterServiceContainer {
        if let factory = findServiceFactory(factoryType) {
            return BuilderRouter(FR.self).builderIfSupport(useSegue: segue, need: identifier)?
                .setContainer(lazy: .init(serviceFactory: factory, routerProvider: self))
        } else {
            return .init(error: DependencyRouterError.serviceFactoryNotFound(FR.ContainerType.ServiceFactory.self))
        }
    }
}
