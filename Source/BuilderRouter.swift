//
//  BuilderRouter.swift
//  DependencyRouter
//
//  Created by Короткий Виталий on 09.09.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import UIKit

public struct BuilderRouter<FR: FactoryRouter> {
    public struct ReadyCreate: BuilderRouterReadyCreate {
        public let factory: FR
    }
    
    public struct ReadySetup<VC: UIViewController>: BuilderRouterReadySetup {
        public let factory: FR
        public let viewController: VC
    }
    
    public init(_ factoryType: FR.Type) { }
    
    public func setContainer(_ container: FR.ContainerType) -> ReadyCreate {
        return ReadyCreate(factory: FR.init(container: container))
    }
}

public struct BuilderRouterReadyPresent<VC: UIViewController> {
    public let viewController: VC
}


public protocol BuilderRouterReadyCreate {
    associatedtype FR: FactoryRouter
    var factory: FR { get }
}

public protocol BuilderRouterReadySetup {
    associatedtype FR: FactoryRouter
    associatedtype VC: UIViewController
    var factory: FR { get }
    var viewController: VC { get }
}

extension BuilderRouter: BuilderRouterReadyCreate where FR.ContainerType == Void {
    public var factory: FR {
        return FR.init(containerAny: Void())!
    }
}

extension BuilderRouterReadyCreate {
    public func create<VC: UIViewController>(use viewController: VC) -> BuilderRouter<FR>.ReadySetup<VC> {
        return .init(factory: factory, viewController: viewController)
    }
}
