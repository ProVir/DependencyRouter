//
//  BuilderRouter.swift
//  DependencyRouter 0.2
//
//  Created by Короткий Виталий on 09.09.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import UIKit

/// Support for test existing ViewController for present before create factory router with container - can the ViewController be used for setup. Usually used with segue with manually tests. This protocol should be inherited only in factory protocols, not in implementations.
public protocol PrepareBuilderSupportFactoryRouter {
    associatedtype VCSetupType: UIViewController
    var setupVCType: VCSetupType.Type { get }
}

// MARK: Builder
/// Builder (begin step) with factory type ready for use
public struct BuilderRouter<BuilderFR: FactoryRouter> {
    /// Builder step: after created factory (may be lazy) with container
    public struct ReadyCreate: BuilderRouterReadyCreate {
        public init(factory: @escaping () -> BuilderFR) { lazyFactory = factory }
        
        public let lazyFactory: () -> BuilderFR
    }
    
    /// Builder step: after create or use of existing ViewController
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
    
    /// Builder step: after create or use of existing ViewController (use lazy create factory)
    public struct LazyReadySetup<VC: UIViewController>: BuilderRouterReadySetup {
        public init(factory: @escaping () -> BuilderFR, viewController: VC, findedForSetupViewController: UIViewController? = nil) {
            self.lazyFactory = factory
            self.viewController = viewController
            self.findedForSetupViewController = findedForSetupViewController
        }
        
        public let lazyFactory: () -> BuilderFR
        public let viewController: VC
        public private(set) weak var findedForSetupViewController: UIViewController?
        
        public func factory() -> BuilderFR { return lazyFactory() }
    }
    
    /// Builder step: before create factory with container with use of existing ViewController, use when need test support existing ViewController for factory. Replace steps container->useVC->setup to useVC?->container->setup
    public struct PrepareBuilder<VC: UIViewController> {
        public init(viewController: VC, findedForSetupViewController: UIViewController) {
            self.viewController = viewController
            self.findedForSetupViewController = findedForSetupViewController
        }
        
        public let viewController: VC
        public private(set) weak var findedForSetupViewController: UIViewController?
        
        public func setContainer(_ container: BuilderFR.ContainerType) -> ReadySetup<VC> {
            return .init(factory: BuilderFR(container: container), viewController: viewController, findedForSetupViewController: findedForSetupViewController)
        }
        
        public func setContainer(lazy container: @autoclosure @escaping () -> BuilderFR.ContainerType) -> LazyReadySetup<VC> {
            return .init(factory: { BuilderFR(container: container()) }, viewController: viewController, findedForSetupViewController: findedForSetupViewController)
        }
    }
    
    /// Builder requred FactoryType
    public init(_ factoryType: BuilderFR.Type) { }
    
    /// Step 1 (variant 1a): Create factory (lazy) with container
    public func setContainer(_ container: BuilderFR.ContainerType) -> ReadyCreate {
        return ReadyCreate(factory: { BuilderFR(container: container) })
    }
    
    /// Step 1 (variant 1b): Create factory (lazy) with lazy container (getted only if support factory in next steps)
    public func setContainer(lazy container: @autoclosure @escaping () -> BuilderFR.ContainerType) -> ReadyCreate {
        return ReadyCreate(factory: { BuilderFR(container: container()) })
    }
}

extension BuilderRouter where BuilderFR: PrepareBuilderSupportFactoryRouter {
    /// Steps swap 1 and 2: Support Prepare step (0) as step 2 - use of existing ViewController if support factory
    public func builderIfSupport<VC: UIViewController>(use viewController: VC) -> PrepareBuilder<VC>? {
        if let vc: BuilderFR.VCSetupType = try? dependencyRouterFindViewController(viewController) {
            return .init(viewController: viewController, findedForSetupViewController: vc)
        } else {
            return nil
        }
    }
    
    /// Steps swap 1 and 2: Support Prepare step (0) as step 2 - use segue if support factory
    public func builderIfSupport(useSegue segue: UIStoryboardSegue, need identifier: String? = nil) -> PrepareBuilder<UIViewController>? {
        if let identifier = identifier, segue.identifier != identifier {
            return nil
        }
        
        return builderIfSupport(use: segue.destination)
    }
}

/// Step 2: Factories with support create ViewController
public protocol BuilderRouterReadyCreate {
    associatedtype FR: FactoryRouter
    var lazyFactory: () -> FR { get }
}

/// Step 3: Factories with support setup existing or created ViewController
public protocol BuilderRouterReadySetup {
    associatedtype FR: FactoryRouter
    associatedtype VC: UIViewController
    
    var viewController: VC { get }
    var findedForSetupViewController: UIViewController? { get }
    
    func factory() -> FR
}

/// Step 1->2: Support auto create factory (skip step 1 and go directly to step 2)
extension BuilderRouter: BuilderRouterReadyCreate where BuilderFR: AutoFactoryRouter {
    public typealias FR = BuilderFR
    public var lazyFactory: () -> FR {
        return { FR() }
    }
}

/// Step 1->3: Support auto create factory (skip step 1 and go directly to step 3, step 2 always ignored after step 0)
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
    
    /// Step 2: use of existing ViewController
    public func use<VC: UIViewController>(_ viewController: VC) -> BuilderRouter<FR>.LazyReadySetup<VC> {
        return .init(factory: lazyFactory, viewController: viewController)
    }
    
    /// Step 2: use segue with ViewController (`segue.destination`)
    public func use(segue: UIStoryboardSegue) -> BuilderRouter<FR>.LazyReadySetup<UIViewController> {
        return .init(factory: lazyFactory, viewController: segue.destination)
    }
}

extension BuilderRouterReadySetup {
    /// Helper for find requred ViewController in created or existing root ViewController 
    public func coreFindForSetupViewController<VCType: UIViewController>() throws -> VCType {
        if let vc: VCType = findedForSetupViewController as? VCType {
            return vc
        } else {
            return try dependencyRouterFindViewController(viewController)
        }
    }
}

// MARK: - Present
/// Step 4 (Last): Present setuped ViewController
public class BuilderRouterReadyPresent<VC: UIViewController> {
    private var router: PresentationRouter
    
    /// Constructor with ViewController to present and default action (use lazy created action)
    public init(viewController: VC, default actionSource: @autoclosure @escaping () -> PresentationAction) {
        self.router = .init(viewController: viewController, actionSource: actionSource)
    }
    
    /// Constructor with always failure when present
    public init(error: Error) {
        self.router = .init(error: error)
    }
    
    // MARK: State and Data
    /// Autoclosure with action as default
    public var defaultActionSource: () -> PresentationAction {
        return self.router.actionSource
    }
    
    /// ViewController for present or error
    public func viewController() throws -> VC {
        return try self.router.viewController() as! VC
    }
    
    /// ViewController for present if ready (not error)
    public var viewControllerIfReady: VC? {
        return self.router.viewControllerIfReady as? VC
    }
    
    /// Error if containt
    public var error: Error? {
        return self.router.error
    }
    
    // MARK: Result without Present
    /// Result as `Bool` used Builder without present
    @discardableResult
    public func isSuccess() -> Bool {
        return self.router.viewControllerIfReady != nil
    }
    
    /// Result as try-catch used Builder without present
    public func completed() throws {
        if let error = self.router.error {
            throw error
        }
    }
    
    /// Result as fatal error if failure Builder without present
    public func completedOrFatalError() {
        DependencyRouterError.tryAsFatalError {
            if let error = self.router.error {
                throw error
            }
        }
    }
    
    /// Result as assertionFailure if failure Builder without present
    public func completedOrAssertionFailure() {
        try? DependencyRouterError.tryAsAssertionFailure {
            if let error = self.router.error {
                throw error
            }
        }
    }
    
    /// Ignore result used Builder without present
    public func ignoreResult() { }
    
    // MARK: Setup for Present
    @discardableResult
    public func prepareHandler(_ handler: @escaping (UIViewController) -> Void) -> Self {
        self.router.addPrepareHandler(handler)
        return self
    }
    
    @discardableResult
    public func postHandler(_ handler: @escaping (UIViewController) -> Void) -> Self {
        self.router.addPostHandler(handler)
        return self
    }
    
    //MARK: Ready to deferred Present
    public func presentationRouter() -> PresentationRouter {
        return self.router
    }
    
    public func presentationRouter(action actionSource: @autoclosure @escaping () -> PresentationAction) -> PresentationRouter {
        var router = self.router
        router.setAction(source: actionSource)
        return router
    }

    // MARK: Present
    /**
     Present ViewController on existing use action and result (success or failure) return in closure.
     
     - Parameters:
        - existingController: the current ViewController on which the created ViewController is presented
        - action: (Optional) custom action if need use, else used default action from source (`var defaultActionSource`)
        - animated: present ViewController with animation if true (default)
        - completionHandler: handler with result presented
     */
    public func present(on existingController: UIViewController?,
                        action: PresentationAction? = nil,
                        animated: Bool = true,
                        completionHandler: @escaping (PresentationActionResult) -> Void) {
        present(on: existingController, action: action, animated: animated, useAssert: false, completionHandler: completionHandler)
    }
    
    /**
     Present ViewController on existing use action and assertionFailure (usually crash in debug regime) if result is failure.
     
     - Parameters:
        - existingController: the current ViewController on which the created ViewController is presented
        - action: (Optional) custom action if need use, else used default action from source (`var defaultActionSource`)
        - animated: present ViewController with animation if true (default)
        - useAssert: when failure present assertionFailure if true (default)
     */
    public func present(on existingController: UIViewController?,
                        action: PresentationAction? = nil,
                        animated: Bool = true,
                        useAssert: Bool = true) {
        present(on: existingController, action: action, animated: animated, useAssert: useAssert, completionHandler: nil)
    }
    
    /**
     Present ViewController on existing use action.
     
     - Parameters:
        - existingController: the current ViewController on which the created ViewController is presented
        - action: (Optional) custom action if need use, else used default action from source (`var defaultActionSource`)
        - animated: present ViewController with animation if true (default)
        - useAssert: when failure present assertionFailure if true
        - completionHandler: (Optional) handler with result presented
     */
    public func present(on existingController: UIViewController?,
                        action: PresentationAction? = nil,
                        animated: Bool = true,
                        useAssert: Bool,
                        completionHandler: ((PresentationActionResult) -> Void)?) {
        if let existingController = existingController {
            router.present(on: existingController, customAction: action, animated: animated, useAssert: useAssert, completionHandler: completionHandler)
        } else if useAssert {
            DependencyRouterError.notReadyPresentingViewController("not found existing ViewController (existingController = nil)")
                .assertionFailure()
        }
    }
}
