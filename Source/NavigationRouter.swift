//
//  NavigationRouter.swift
//  DependencyRouter
//
//  Created by Короткий Виталий on 19.09.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import UIKit


open class BaseNavigationRouter: PresentNavigationRouter, SegueRouterSupport {
    open weak var associatedViewController: UIViewController?
    open weak var source: (AnyObject & BaseFactoryInputSource)?
    
    public let segueRouter = SegueRouter()
    
    open var sourceList: [BaseFactoryInputSource] {
        var list = [BaseFactoryInputSource]()
        
        if let source = self.source { list.append(source) }
        if let source = self as? BaseFactoryInputSource { list.append(source) }
        if let source = self.associatedViewController as? BaseFactoryInputSource { list.append(source) }
        
        return list
    }
    
    public init(viewController: UIViewController?) {
        self.associatedViewController = viewController
    }


    @discardableResult
    public func prepare(for segue: UIStoryboardSegue, sender: Any?) -> Bool {
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
}


public class NullModel {
    static let null = NullModel()
    private init() { }
}

open class NavigationRouter<VC: UIViewController, M: AnyObject>: BaseNavigationRouter {
    ///RouterModel with data for next Screens.
    public let model: M
    
    ///Require ViewController, RouterModel (can be ViewModel or Model).
    public init(viewController: VC, routerModel: M) {
        self.model = routerModel
        super.init(viewController: viewController)
    }
    
    ///Current ViewController for router.
    public var viewController: VC {
        return associatedViewController as! VC
    }
}

extension NavigationRouter where M == NullModel {
    ///Require ViewController and Provider.
    public convenience init(viewController: VC) {
        self.init(viewController: viewController, routerModel: NullModel.null)
    }
}
