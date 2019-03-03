//
//  ApplicationRouter.swift
//  DependencyRouter 0.3
//
//  Created by Короткий Виталий on 03/03/2019.
//  Copyright © 2019 ProVir. All rights reserved.
//

import Foundation

open class ApplicationRouter<ContainerType> {
    private let container: ContainerType
    
    public init(container: ContainerType) {
        self.container = container
    }
    
    //MARK: Builder
    public func builder<FR: FactoryRouter>(_ factoryType: FR.Type)
                                        -> BuilderRouter<FR>.ReadyCreate where FR.ContainerType == ContainerType {
        return BuilderRouter(FR.self).setContainer(container)
    }
    
    public func builderIfSupport<FR: FactoryRouter & PrepareBuilderSupportFactoryRouter, VC: UIViewController>(_ factoryType: FR.Type, use viewController: VC)
                                        -> BuilderRouter<FR>.ReadySetup<VC>? where FR.ContainerType == ContainerType {
        return BuilderRouter(FR.self).builderIfSupport(use: viewController)?.setContainer(container)
    }
    
    public func builderIfSupport<FR: FactoryRouter & PrepareBuilderSupportFactoryRouter>(_ factoryType: FR.Type, useSegue segue: UIStoryboardSegue, need identifier: String? = nil)
                                        -> BuilderRouter<FR>.ReadySetup<UIViewController>? where FR.ContainerType == ContainerType {
            return BuilderRouter(FR.self).builderIfSupport(useSegue: segue, need: identifier)?.setContainer(container)
    }
    
    //MARK:
    
}
