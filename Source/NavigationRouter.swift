//
//  NavigationRouter.swift
//  DependencyRouter
//
//  Created by Короткий Виталий on 19.09.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import UIKit

open class BaseNavigationRouter: PresentNavigationRouter {
    open weak var associatedViewController: UIViewController?
    open weak var source: (AnyObject & BaseFactoryInputSource)?
    
    open var sourceList: [BaseFactoryInputSource] {
        var list = [BaseFactoryInputSource]()
        
        if let source = self.source { list.append(source) }
        if let source = self as? BaseFactoryInputSource { list.append(source) }
        if let source = self.associatedViewController as? BaseFactoryInputSource { list.append(source) }
        
        return list
    }
    
    init(viewController: UIViewController?) {
        self.associatedViewController = viewController
    }

    func setSourceList(_ sourceList: [BaseFactoryInputSource], forSegueIdentifier identifier: String, onlyOne: Bool = false) {
        let store = SourceStore()
        store.sourceList = sourceList
        store.onlyOne = onlyOne
        sourcesForSegues[identifier] = store
    }
    
    func setWeakSource(_ source: (AnyObject & BaseFactoryInputSource), forSegueIdentifier identifier: String, onlyOne: Bool = false) {
        let store = SourceStore()
        store.weakSource = source
        store.onlyOne = onlyOne
        sourcesForSegues[identifier] = store
    }
    
    func sourceListForSegue(withIdentifier identifier: String, removeIfOnlyOne: Bool) -> [BaseFactoryInputSource] {
        guard let store = sourcesForSegues[identifier] else {
            return []
        }
        
        if removeIfOnlyOne && store.onlyOne {
            sourcesForSegues.removeValue(forKey: identifier)
        }
        
        if let list = store.weakSource {
            return [list]
        } else {
            return store.sourceList
        }
    }
    
    @discardableResult
    func prepare(for segue: UIStoryboardSegue, sender: Any?) -> Bool {
        let list = sourceListForSegue(withIdentifier: segue.identifier ?? "", removeIfOnlyOne: true)
        
        if list.isEmpty {
            return Router.prepare(for: segue, sender: sender, sourceList: sourceList)
        } else {
            return Router.prepare(for: segue, sender: sender, sourceList: list)
        }
    }
    
    @discardableResult
    func unwindSegue(_ segue: UIStoryboardSegue) -> Bool {
        return Router.unwindSegue(segue, sourceList: sourceList)
    }
    
    public func performSegue(withIdentifier identifier: String, sourceList: [BaseFactoryInputSource], sender: Any?) {
        setSourceList(sourceList, forSegueIdentifier: identifier, onlyOne: true)
        associatedViewController?.performSegue(withIdentifier: identifier, sender: sender)
    }
    
    public func performSegue(withIdentifier identifier: String, sender: Any? = nil) {
        associatedViewController?.performSegue(withIdentifier: identifier, sender: sender)
    }
    
    //MARK: - Private
    private class SourceStore {
        weak var weakSource: (AnyObject & BaseFactoryInputSource)?
        var sourceList: [BaseFactoryInputSource] = []
        var onlyOne: Bool = false
    }
    
    private var sourcesForSegues: [String: SourceStore] = [:]
}
