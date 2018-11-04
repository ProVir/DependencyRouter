//
//  ObjCPresentationRouter.swift
//  DependencyRouter 0.2
//
//  Created by Короткий Виталий on 03/10/2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import UIKit

extension PresentationRouter {
    public func toObjC() -> ObjCPresentationRouter {
        return ObjCPresentationRouter(self)
    }
}

//MARK: Router
@objc(DRPresentationRouter)
open class ObjCPresentationRouter: NSObject {
    var router: PresentationRouter
    
    public init(_ router: PresentationRouter) {
        self.router = router
    }
    
    //MARK: State and Data
    @objc var viewController: UIViewController? {
        return router.viewControllerIfReady
    }
    
    @objc var error: Error? {
        return router.error
    }
    
    @objc public func addPrepareHandler(_ handler: @escaping (UIViewController)->Void) {
        router.addPrepareHandler(handler)
    }
    
    @objc public func addPostHandler(_ handler: @escaping (UIViewController)->Void) {
        router.addPostHandler(handler)
    }
    
    
    //MARK: Present
    @objc public func present(on existingController: UIViewController, animated: Bool) {
        router.present(on: existingController, animated: animated, assertWhenFailure: true, completionHandler: nil)
    }
    
    @objc public func present(on existingController: UIViewController, animated: Bool, assertWhenFailure: Bool) {
        router.present(on: existingController, animated: animated, assertWhenFailure: assertWhenFailure, completionHandler: nil)
    }
    
    @objc public func present(on existingController: UIViewController, animated: Bool, completionHandler: @escaping (Error?)->Void) {
        router.present(on: existingController, animated: animated, assertWhenFailure: false) {
            switch $0 {
            case .success: completionHandler(nil)
            case .failure(let error): completionHandler(error)
            }
        }
    }
    
    @objc public func present(on existingController: UIViewController, animated: Bool, assertWhenFailure: Bool, completionHandler: ((Error?)->Void)?) {
        if let handler = completionHandler {
            router.present(on: existingController, animated: animated, assertWhenFailure: assertWhenFailure) {
                switch $0 {
                case .success: handler(nil)
                case .failure(let error): handler(error)
                }
            }
        } else {
            router.present(on: existingController, animated: animated, assertWhenFailure: assertWhenFailure)
        }
    }
}

