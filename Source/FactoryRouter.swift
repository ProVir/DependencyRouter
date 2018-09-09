//
//  FactoryRouter.swift
//  DependencyRouter
//
//  Created by Короткий Виталий on 08.09.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import UIKit


//MARK: Base
public protocol FactoryRouter: CoreFactoryRouter {
    associatedtype ContainerType
    init(container: ContainerType)
}

public protocol CoreFactoryRouter {
    init?(containerAny: Any)
}

extension FactoryRouter {
    public init?(containerAny: Any) {
        if let container = containerAny as? ContainerType {
            self.init(container: container)
        } else {
            return nil
        }
    }
}


///Wrappers for childViewController support
public protocol ContainerSupportRouter {
    func findViewController<VCType: UIViewController>() -> VCType?
}

//MARK: - Helpers

///UIViewController -> VCType with support NavigationController wrapper
public func factoryRouterFindViewController<VCType: UIViewController>(_ viewController: UIViewController) throws -> VCType {
    if let vc = viewController as? VCType {
        return vc
    } else if let vc: VCType = (viewController as? ContainerSupportRouter)?.findViewController() {
        return vc
    } else {
        throw FactoryRouterError.viewControllerNotFound(VCType.self)
    }
}
