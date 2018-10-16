//
//  ObjCNavigationRouter.swift
//  DependencyRouter
//
//  Created by Короткий Виталий on 03/10/2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import UIKit

@objc(DRNavigationRouter)
open class ObjCNavigationRouter: NSObject, SimplePresentNavigationRouter, CallbackFactoryInputSource, CallbackUnwindInputSource {
    @objc open weak var associatedViewController: UIViewController?
    open weak var source: (AnyObject & BaseFactoryInputSource)?
    
    public let segueRouter = SegueRouter()
    
    open var sourceList: [BaseFactoryInputSource] {
        var list = [BaseFactoryInputSource]()
        
        if let source = self.source { list.append(source) }
        if let source = self.associatedViewController as? BaseFactoryInputSource { list.append(source) }
        list.append(self)
        
        return list
    }
    
    @objc public init(_ viewController: UIViewController?) {
        self.associatedViewController = viewController
        super.init()
    }
    
    @discardableResult
    open func prepare(for segue: UIStoryboardSegue, sender: Any?) -> Bool {
        if segueRouter.contains(segueIdentifier: segue.identifier ?? "") {
            return segueRouter.prepare(for: segue, sender: sender)
        } else {
            return Router.prepare(for: segue, sender: sender, sourceList: sourceList)
        }
    }
    
    @discardableResult
    open func unwindSegue(_ segue: UIStoryboardSegue) -> Bool {
        return Router.unwindSegue(segue, sourceList: sourceList)
    }
    
    @discardableResult
    open func dismiss(animated: Bool = true) -> Bool {
        if let viewController = associatedViewController {
            return Router.dismiss(viewController, animated: animated)
        } else {
            return false
        }
    }
    
    open func performSegue(withIdentifier identifier: String, factory: FactorySupportInputSource, sourceList: [BaseFactoryInputSource], sender: Any?) {
        segueRouter.set(forSegueIdentifier: identifier, factory: factory, sourceList: sourceList, onlyOne: true)
        associatedViewController?.performSegue(withIdentifier: identifier, sender: sender)
    }
    
    open func callbackForFactoryRouter(_ routerType: CoreFactoryRouter.Type, identifier: String?, sender: Any?) -> Any? {
        return self
    }
    
    public func callbackForUnwindRouter(_ unwindType: CoreUnwindCallbackRouter.Type, segueIdentifier: String?) -> Any? {
        return self
    }
}


