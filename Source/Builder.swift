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
        public init(factory: FR) { storeFactory = factory }
        
        public let storeFactory: FR
        public func factory() -> FR { return storeFactory }
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


public protocol BuilderRouterReadyCreate {
    associatedtype FR: FactoryRouter
    func factory() -> FR
}

public protocol BuilderRouterReadySetup {
    associatedtype FR: FactoryRouter
    associatedtype VC: UIViewController
    var factory: FR { get }
    var viewController: VC { get }
}

extension BuilderRouter: BuilderRouterReadyCreate where FR: AutoFactoryRouter {
    public func factory() -> FR {
        return FR()
    }
}

extension BuilderRouterReadyCreate {
    public func use<VC: UIViewController>(_ viewController: VC) -> BuilderRouter<FR>.ReadySetup<VC> {
        return .init(factory: factory(), viewController: viewController)
    }
    
    public func use(segue: UIStoryboardSegue) -> BuilderRouter<FR>.ReadySetup<UIViewController> {
        return .init(factory: factory(), viewController: segue.destination)
    }
}


//MARK: - Present

public class BuilderRouterReadyPresent<VC: UIViewController> {
    private var handler: PresentationHandler
    
    public init(viewController: VC, default presentationSource: @autoclosure @escaping ()->PresentationRouter) {
        self.handler = .init(viewController: viewController, presentationSource: presentationSource)
    }
    
    public init(error: Error) {
        self.handler = .init(error: error)
    }
    
    //MARK: State and Data
    public var defaultPresentationSource: ()->PresentationRouter {
        return self.handler.presentationSource
    }
    
    public func viewController() throws -> VC {
        return try self.handler.viewController() as! VC
    }
    
    public var viewControllerIfReady: VC? {
        return self.handler.viewControllerIfReady as? VC
    }
    
    public var error: Error? {
        return self.handler.error
    }
    
    
    //MARK: Result without Present
    @discardableResult
    public func isSuccess() -> Bool {
        return self.handler.viewControllerIfReady != nil
    }
    
    public func completed() throws {
        if let error = self.handler.error {
            throw error
        }
    }
    
    public func completedOrFatalError() {
        DependencyRouterError.tryAsFatalError {
            if let error = self.handler.error {
                throw error
            }
        }
    }
    
    public func completedOrAssert() {
        try? DependencyRouterError.tryAsAssert {
            if let error = self.handler.error {
                throw error
            }
        }
    }
    
    public func ignoreResult() { }
    
    
    //MARK: Setup for Present
    @discardableResult
    public func prepareHandler(_ handler: @escaping ()->Void) -> BuilderRouterReadyPresent<VC> {
        self.handler.addPrepareHandler(handler)
        return self
    }
    
    @discardableResult
    public func postHandler(_ handler: @escaping ()->Void) -> BuilderRouterReadyPresent<VC> {
        self.handler.addPostHandler(handler)
        return self
    }
    
    //MARK: Ready to deferred Present
    public func presentationHandler() -> PresentationHandler {
        return self.handler
    }
    
    public func presentationHandler(presentation presentationSource: @autoclosure @escaping ()->PresentationRouter) -> PresentationHandler {
        var handler = self.handler
        handler.setPresentationRouter(presentationSource)
        return handler
    }

    //MARK: Present
    public func present(on existingController: UIViewController, presentation: PresentationRouter? = nil, animated: Bool = true, completionHandler: @escaping (PresentationRouterResult)->Void) {
        present(on: existingController, presentation: presentation, animated: animated, assertWhenFailure: false, completionHandler: completionHandler)
    }
    
    public func present(on existingController: UIViewController, presentation: PresentationRouter? = nil, animated: Bool = true, assertWhenFailure: Bool = true) {
        present(on: existingController, presentation: presentation, animated: animated, assertWhenFailure: assertWhenFailure, completionHandler: nil)
    }
    
    public func present(on existingController: UIViewController, presentation: PresentationRouter? = nil, animated: Bool = true, assertWhenFailure: Bool, completionHandler: ((PresentationRouterResult)->Void)?) {
        self.handler.present(on: existingController, customPresentation: presentation, animated: animated, assertWhenFailure: assertWhenFailure, completionHandler: completionHandler)
    }
}
