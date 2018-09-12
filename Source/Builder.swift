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

public class BuilderRouterReadyPresent<VC: UIViewController> {
    public let viewController: VC
    public let defaultPresentationSource: ()->PresentationRouter
    
    private var prepareHandlers: [()->Void] = []
    private var postHandlers: [()->Void] = []
    
    public init(viewController: VC, default presentationSource: @autoclosure @escaping ()->PresentationRouter) {
        self.viewController = viewController
        self.defaultPresentationSource = presentationSource
    }
    
    @discardableResult
    public func prepareHandler(_ handler: @escaping ()->Void) -> BuilderRouterReadyPresent<VC> {
        prepareHandlers.append(handler)
        return self
    }
    
    @discardableResult
    public func postHandler(_ handler: @escaping ()->Void) -> BuilderRouterReadyPresent<VC> {
        postHandlers.append(handler)
        return self
    }

    public func present(on existingController: UIViewController, animated: Bool = true) {
        let handler = PresentationRouterHandler(presentation: defaultPresentationSource(), viewController: viewController, prepareHandlers: prepareHandlers, postHandlers: postHandlers)
        handler.present(on: existingController, animated: animated, completionHandler: nil, assertWhenFailure: true)
    }
    
    public func present(_ presentation: PresentationRouter, on existingController: UIViewController, animated: Bool = true) {
        let handler = PresentationRouterHandler(presentation: presentation, viewController: viewController, prepareHandlers: prepareHandlers, postHandlers: postHandlers)
        handler.present(on: existingController, animated: animated, completionHandler: nil, assertWhenFailure: true)
    }
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

extension BuilderRouter: BuilderRouterReadyCreate where FR.ContainerType: AutoServiceContainer {
    public var factory: FR {
        return FR.init(container: FR.ContainerType.init())
    }
}

extension BuilderRouterReadyCreate {
    public func create<VC: UIViewController>(use viewController: VC) -> BuilderRouter<FR>.ReadySetup<VC> {
        return .init(factory: factory, viewController: viewController)
    }
}
