//
//  InputSource.swift
//  Example
//
//  Created by Короткий Виталий on 17.09.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import Foundation


public protocol BaseFactoryInputSource { }

public protocol FactorySupportInputSource: CoreFactoryRouter {
    func setup(_ viewController: UIViewController, sourceList: [BaseFactoryInputSource], identifier: String?, sender: Any?) throws
}




//MARK: Support Builder
extension BuilderRouterReadySetup where FR: FactoryRouter, FR: FactorySupportInputSource {
    public func setup(source: BaseFactoryInputSource, identifier: String? = nil, sender: Any? = nil) -> BuilderRouterReadyPresent<VC> {
        return setup(sourceList: [source], identifier: identifier, sender: sender)
    }
    
    public func setup(sourceList: [BaseFactoryInputSource], identifier: String? = nil, sender: Any? = nil) -> BuilderRouterReadyPresent<VC> {
        
        let factory = self.factory
        DependencyRouterError.tryAsFatalError {
            try factory.setup(viewController, sourceList: sourceList, identifier: identifier, sender: sender)
        }
 
        return .init(viewController: viewController, default: factory.defaultPresentation())
    }
}

extension BuilderRouterReadyCreate where FR: CreatorFactoryRouter, FR: FactorySupportInputSource {
    public func createAndSetup(source: BaseFactoryInputSource, identifier: String? = nil, sender: Any? = nil) -> BuilderRouterReadyPresent<FR.VCCreateType> {
        return createAndSetup(sourceList: [source], identifier: identifier, sender: sender)
    }
    
    public func createAndSetup(sourceList: [BaseFactoryInputSource], identifier: String? = nil, sender: Any? = nil) -> BuilderRouterReadyPresent<FR.VCCreateType> {
        let factory = self.factory
        let viewController = factory.createViewController()
        
        DependencyRouterError.tryAsFatalError {
            try factory.setup(viewController, sourceList: sourceList, identifier: identifier, sender: sender)
        }
        
        return .init(viewController: viewController, default: factory.defaultPresentation())
    }
}
