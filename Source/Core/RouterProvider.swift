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
    init(_ serviceFactory: ServiceFactory, routerProvider: RouterProvider)
}

public protocol RouterProvider: class {
    func isSupport<FR: FactoryRouter>(_ factoryType: FR.Type) -> Bool where FR.ContainerType: RouterServiceContainer
    func factory<FR: FactoryRouter>(_ factoryType: FR.Type) throws -> FR where FR.ContainerType: RouterServiceContainer
}

extension RouterProvider {
    public func factoryOrFatalError<FR: FactoryRouter>(_ factoryType: FR.Type = FR.self) -> FR where FR.ContainerType: RouterServiceContainer {
        return DependencyRouterError.tryAsFatalError { try factory(factoryType) }
    }
}

extension BuilderRouter where BuilderFR.ContainerType: RouterServiceContainer {
    public func useProvider(_ provider: RouterProvider) -> BuilderRouter<BuilderFR>.ReadyCreate {
        do {
            let factory = try provider.factory(BuilderFR.self)
            return .init(factory: { factory })
        } catch {
            return .init(error: error)
        }
    }
    
    public func useProviderIfSupport(_ provider: RouterProvider) -> BuilderRouter<BuilderFR>.ReadyCreate? {
        do {
            let factory = try provider.factory(BuilderFR.self)
            return .init(factory: { factory })
        } catch {
            return nil
        }
    }
}

extension BuilderRouter where BuilderFR.ContainerType: RouterServiceContainer, BuilderFR: PrepareBuilderSupportFactoryRouter {
    public func builderIfSupport<VC: UIViewController>(provider: RouterProvider, use viewController: VC) -> BuilderRouter<BuilderFR>.ReadySetup<VC>? {
        if let findedVC: BuilderFR.VCSetupType = try? dependencyRouterFindViewController(viewController),
            let factory = try? provider.factory(BuilderFR.self) {
            return .init(factory: factory, viewController: viewController, findedForSetupViewController: findedVC)
        } else {
            return nil
        }
    }
    
    public func builderIfSupport(provider: RouterProvider, useSegue segue: UIStoryboardSegue, need identifier: String? = nil) -> BuilderRouter<BuilderFR>.ReadySetup<UIViewController>? {
        if let identifier = identifier, segue.identifier != identifier {
            return nil
        }
        
        return builderIfSupport(provider: provider, use: segue.destination)
    }
}
