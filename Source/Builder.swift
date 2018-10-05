//
//  BuilderRouter.swift
//  DependencyRouter
//
//  Created by Короткий Виталий on 09.09.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import UIKit

//MARK: Builder
public struct BuilderRouter<FR: FactoryRouter> {
    public struct ReadyCreate: BuilderRouterReadyCreate {
        public init(factory: @autoclosure @escaping ()->FR) { lazyFactory = factory }
        
        public let lazyFactory: ()->FR
    }
    
    public struct ReadySetup<VC: UIViewController>: BuilderRouterReadySetup {
        public init(factory: FR, viewController: VC) {
            self.storeFactory = factory
            self.viewController = viewController
        }
        
        public let storeFactory: FR
        public let viewController: VC
        
        public func factory() -> FR { return storeFactory }
    }
    
    public struct LazyReadySetup<VC: UIViewController>: BuilderRouterReadySetup {
        public init(factory: @escaping ()->FR, viewController: VC) {
            self.lazyFactory = factory
            self.viewController = viewController
        }
        
        public let lazyFactory: ()->FR
        public let viewController: VC
        
        public func factory() -> FR { return lazyFactory() }
    }
    
    public init(_ factoryType: FR.Type) { }
    
    public func setContainer(_ container: @autoclosure @escaping ()->FR.ContainerType) -> ReadyCreate {
        return ReadyCreate(factory: FR(container: container()))
    }
}


public protocol BuilderRouterReadyCreate {
    associatedtype FR: FactoryRouter
    var lazyFactory: ()->FR { get }
}

public protocol BuilderRouterReadySetup {
    associatedtype FR: FactoryRouter
    associatedtype VC: UIViewController
    var viewController: VC { get }
    func factory() -> FR
}

extension BuilderRouter: BuilderRouterReadyCreate where FR: AutoFactoryRouter {
    public var lazyFactory: () -> FR {
        return { FR() }
    }
}

extension BuilderRouterReadyCreate {
    func factory() -> FR {
        return lazyFactory()
    }
    
    public func use<VC: UIViewController>(_ viewController: VC) -> BuilderRouter<FR>.LazyReadySetup<VC> {
        return .init(factory: lazyFactory, viewController: viewController)
    }
    
    public func use(segue: UIStoryboardSegue) -> BuilderRouter<FR>.LazyReadySetup<UIViewController> {
        return .init(factory: lazyFactory, viewController: segue.destination)
    }
}


//MARK: - Present

public class BuilderRouterReadyPresent<VC: UIViewController> {
    private var router: PresentationRouter
    
    public init(viewController: VC, default actionSource: @autoclosure @escaping ()->PresentationAction) {
        self.router = .init(viewController: viewController, actionSource: actionSource)
    }
    
    public init(error: Error) {
        self.router = .init(error: error)
    }
    
    //MARK: State and Data
    public var defaultActionSource: ()->PresentationAction {
        return self.router.actionSource
    }
    
    public func viewController() throws -> VC {
        return try self.router.viewController() as! VC
    }
    
    public var viewControllerIfReady: VC? {
        return self.router.viewControllerIfReady as? VC
    }
    
    public var error: Error? {
        return self.router.error
    }
    
    
    //MARK: Result without Present
    @discardableResult
    public func isSuccess() -> Bool {
        return self.router.viewControllerIfReady != nil
    }
    
    public func completed() throws {
        if let error = self.router.error {
            throw error
        }
    }
    
    public func completedOrFatalError() {
        DependencyRouterError.tryAsFatalError {
            if let error = self.router.error {
                throw error
            }
        }
    }
    
    public func completedOrAssert() {
        try? DependencyRouterError.tryAsAssert {
            if let error = self.router.error {
                throw error
            }
        }
    }
    
    public func ignoreResult() { }
    
    
    //MARK: Setup for Present
    @discardableResult
    public func prepareHandler(_ handler: @escaping ()->Void) -> BuilderRouterReadyPresent<VC> {
        self.router.addPrepareHandler(handler)
        return self
    }
    
    @discardableResult
    public func postHandler(_ handler: @escaping ()->Void) -> BuilderRouterReadyPresent<VC> {
        self.router.addPostHandler(handler)
        return self
    }
    
    //MARK: Ready to deferred Present
    public func presentationRouter() -> PresentationRouter {
        return self.router
    }
    
    public func presentationRouter(action actionSource: @autoclosure @escaping ()->PresentationAction) -> PresentationRouter {
        var router = self.router
        router.setAction(actionSource)
        return router
    }

    //MARK: Present
    public func present(on existingController: UIViewController, action: PresentationAction? = nil, animated: Bool = true, completionHandler: @escaping (PresentationActionResult)->Void) {
        present(on: existingController, action: action, animated: animated, assertWhenFailure: false, completionHandler: completionHandler)
    }
    
    public func present(on existingController: UIViewController, action: PresentationAction? = nil, animated: Bool = true, assertWhenFailure: Bool = true) {
        present(on: existingController, action: action, animated: animated, assertWhenFailure: assertWhenFailure, completionHandler: nil)
    }
    
    public func present(on existingController: UIViewController, action: PresentationAction? = nil, animated: Bool = true, assertWhenFailure: Bool, completionHandler: ((PresentationActionResult)->Void)?) {
        router.present(on: existingController, customAction: action, animated: animated, assertWhenFailure: assertWhenFailure, completionHandler: completionHandler)
    }
}
