//
//  BuilderRouter.swift
//  DependencyRouter
//
//  Created by Короткий Виталий on 09.09.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import UIKit

public protocol PrepareBuilderSupportFactoryRouter {
    associatedtype VCSetupType: UIViewController
    var setupVCType: VCSetupType.Type { get }
}

//MARK: Builder
public struct BuilderRouter<BuilderFR: FactoryRouter> {
    public struct ReadyCreate: BuilderRouterReadyCreate {
        public init(factory: @escaping ()->BuilderFR) { lazyFactory = factory }
        
        public let lazyFactory: ()->BuilderFR
    }
    
    public struct ReadySetup<VC: UIViewController>: BuilderRouterReadySetup {
        public init(factory: BuilderFR, viewController: VC, findedForSetupViewController: UIViewController? = nil) {
            self.storeFactory = factory
            self.viewController = viewController
            self.findedForSetupViewController = findedForSetupViewController
        }
        
        public let storeFactory: BuilderFR
        public let viewController: VC
        public private(set) weak var findedForSetupViewController: UIViewController?
        
        public func factory() -> BuilderFR { return storeFactory }
    }
    
    public struct LazyReadySetup<VC: UIViewController>: BuilderRouterReadySetup {
        public init(factory: @escaping ()->BuilderFR, viewController: VC, findedForSetupViewController: UIViewController? = nil) {
            self.lazyFactory = factory
            self.viewController = viewController
            self.findedForSetupViewController = findedForSetupViewController
        }
        
        public let lazyFactory: ()->BuilderFR
        public let viewController: VC
        public private(set) weak var findedForSetupViewController: UIViewController?
        
        public func factory() -> BuilderFR { return lazyFactory() }
    }
    
    public struct PrepareBuilder<VC: UIViewController> {
        public init(viewController: VC, findedForSetupViewController: UIViewController) {
            self.viewController = viewController
            self.findedForSetupViewController = findedForSetupViewController
        }
        
        public let viewController: VC
        public private(set) weak var findedForSetupViewController: UIViewController?
        
        public func setContainer(_ container: BuilderFR.ContainerType) -> ReadySetup<VC> {
            return .init(factory: FR(container: container), viewController: viewController, findedForSetupViewController: findedForSetupViewController)
        }
        
        public func setContainer(lazy container: @autoclosure @escaping ()->BuilderFR.ContainerType) -> LazyReadySetup<VC> {
            return .init(factory: { FR(container: container()) }, viewController: viewController, findedForSetupViewController: findedForSetupViewController)
        }
    }
    
    public init(_ factoryType: BuilderFR.Type) { }
    
    public func setContainer(_ container: BuilderFR.ContainerType) -> ReadyCreate {
        return ReadyCreate(factory: { BuilderFR(container: container) })
    }
    
    public func setContainer(lazy container: @autoclosure @escaping ()->BuilderFR.ContainerType) -> ReadyCreate {
        return ReadyCreate(factory: { BuilderFR(container: container()) })
    }
}

extension BuilderRouter where BuilderFR: PrepareBuilderSupportFactoryRouter {
    public func builderIfSupport<VC: UIViewController>(use viewController: VC) -> PrepareBuilder<VC>? {
        if let vc: BuilderFR.VCSetupType = try? dependencyRouterFindViewController(viewController) {
            return .init(viewController: viewController, findedForSetupViewController: vc)
        } else {
            return nil
        }
    }
    
    public func builderIfSupport(useSegue segue: UIStoryboardSegue, need identifier: String? = nil) -> PrepareBuilder<UIViewController>? {
        if let identifier = identifier, segue.identifier != identifier {
            return nil
        }
        
        return builderIfSupport(use: segue.destination)
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
    var findedForSetupViewController: UIViewController? { get }
    
    func factory() -> FR
}

extension BuilderRouter: BuilderRouterReadyCreate where BuilderFR: AutoFactoryRouter {
    public typealias FR = BuilderFR
    public var lazyFactory: () -> FR {
        return { FR() }
    }
}

extension BuilderRouter.PrepareBuilder: BuilderRouterReadySetup where BuilderFR: AutoFactoryRouter {
    public typealias FR = BuilderFR
    public func factory() -> FR {
        return FR()
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

extension BuilderRouterReadySetup {
    public func coreFindForSetupViewController<VCType: UIViewController>() throws -> VCType {
        if let vc: VCType = findedForSetupViewController as? VCType {
            return vc
        } else {
            return try dependencyRouterFindViewController(viewController)
        }
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
