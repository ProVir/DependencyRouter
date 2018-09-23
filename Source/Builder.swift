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

public class BuilderRouterReadyPresent<VC: UIViewController> {
    private enum Store {
        case viewController(VC)
        case error(Error)
    }
    
    private let store: Store
    private var prepareHandlers: [()->Void] = []
    private var postHandlers: [()->Void] = []
    
    public let defaultPresentationSource: ()->PresentationRouter
    
    public func viewController() throws -> VC {
        switch store {
        case .viewController(let vc): return vc
        case .error(let error): throw error
        }
    }
    
    public init(viewController: VC, default presentationSource: @autoclosure @escaping ()->PresentationRouter) {
        self.store = .viewController(viewController)
        self.defaultPresentationSource = presentationSource
    }
    
    public init(error: Error) {
        self.store = .error(error)
        self.defaultPresentationSource = { NotPresentationRouter() }
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

    public func present(on existingController: UIViewController, animated: Bool = true, assertWhenFailure: Bool = true, completionHandler: ((PresentationRouterResult)->Void)? = nil) {
        present(on: existingController, presentation: nil, animated: animated, assertWhenFailure: assertWhenFailure, completionHandler: completionHandler)
    }
    
    public func present(on existingController: UIViewController, presentation: PresentationRouter?, animated: Bool = true, assertWhenFailure: Bool = true, completionHandler: ((PresentationRouterResult)->Void)? = nil) {
        //1. Unwrap VC
        let viewController: VC
        switch self.store {
        case .viewController(let vc):
            viewController = vc
            
        case .error(let error):
            completionHandler?(.failure(error))
            if assertWhenFailure {
                try? DependencyRouterError.tryAsAssert { throw error }
            }
            return
        }
        
        //2. Present VC
        let handler = PresentationRouterHandler(presentation: presentation ?? defaultPresentationSource(),
                                                viewController: viewController,
                                                prepareHandlers: prepareHandlers,
                                                postHandlers: postHandlers)
        handler.present(on: existingController, animated: animated, assertWhenFailure: assertWhenFailure, completionHandler: completionHandler)
    }
    
    
    /// Empty stub when used segue or need only setup existing viewController.
    @discardableResult
    public func isSuccess() -> Bool {
        if case .viewController = self.store {
            return true
        } else {
            return false
        }
    }
    
    /// Empty stub when used segue or need only setup existing viewController.
    public func completed() throws {
        if case let .error(error) = self.store {
            throw error
        }
    }
    
    /// Empty stub when used segue or need only setup existing viewController.
    public func completedOrFatalError() {
        DependencyRouterError.tryAsFatalError {
            if case let .error(error) = self.store {
                throw error
            }
        }
    }
    
    /// Empty stub when used segue or need only setup existing viewController.
    public func completedOrAssert() {
        try? DependencyRouterError.tryAsAssert {
            if case let .error(error) = self.store {
                throw error
            }
        }
    }
    
    /// Empty stub when used segue or need only setup existing viewController.
    public func ignoreResult() { }
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
