//
//  SegueRouter.swift
//  DependencyRouter
//
//  Created by Короткий Виталий on 20.09.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import UIKit

public class SegueRouter {
    public init() { }
    
    // MARK: Set for segues
    public func set(forSegueIdentifier identifier: String, factory: @autoclosure @escaping () -> FactorySupportInputSource, sourceList: [BaseFactoryInputSource], onlyOne: Bool = false) {
        let store = Store()
        store.factory = factory
        store.sourceList = sourceList
        store.onlyOne = onlyOne
        mapSegues[identifier] = store
    }
    
    public func set(forSegueIdentifier identifier: String, sourceList: [BaseFactoryInputSource], onlyOne: Bool = false) {
        let store = Store()
        store.sourceList = sourceList
        store.onlyOne = onlyOne
        mapSegues[identifier] = store
    }
    
    public func set(forSegueIdentifier identifier: String, factory: @autoclosure @escaping () -> FactorySupportInputSource, weakSource: (AnyObject & BaseFactoryInputSource), onlyOne: Bool = false) {
        let store = Store()
        store.factory = factory
        store.weakSource = weakSource
        store.onlyOne = onlyOne
        mapSegues[identifier] = store
    }
    
    public func set(forSegueIdentifier identifier: String, weakSource: (AnyObject & BaseFactoryInputSource), onlyOne: Bool = false) {
        let store = Store()
        store.weakSource = weakSource
        store.onlyOne = onlyOne
        mapSegues[identifier] = store
    }
    
    // MARK: Get and remove
    public func contains(segueIdentifier identifier: String) -> Bool {
        return mapSegues[identifier] != nil
    }
    
    public func get(withSegueIdentifier identifier: String) -> (FactorySupportInputSource?, [BaseFactoryInputSource], onlyOne: Bool)? {
        guard let store = mapSegues[identifier] else {
            return nil
        }
        
        let factory = store.factory?()
        let sources: [BaseFactoryInputSource]
        
        if !store.sourceList.isEmpty {
            sources = store.sourceList
        } else if let source = store.weakSource {
            sources = [source]
        } else {
            sources = []
        }
        
        return (factory, sources, store.onlyOne)
    }
    
    @discardableResult
    public func remove(withSegueIdentifier identifier: String) -> Bool {
        return mapSegues.removeValue(forKey: identifier) != nil
    }
    
    public func removeAll() {
        mapSegues.removeAll()
    }
    
    // MARK: Perform segue
    @discardableResult
    public func prepare(for segue: UIStoryboardSegue, sender: Any?) -> Bool {
        //1. Get
        guard let (storeFactory, sourceList, onlyOne) = get(withSegueIdentifier: segue.identifier ?? "") else {
            return false
        }
        
        if onlyOne {
            remove(withSegueIdentifier: segue.identifier ?? "")
        }
        
        //2. Find Factory and VC
        let viewController: UIViewController
        let factory: FactorySupportInputSource
        
        if let storeFactory = storeFactory {
            viewController = segue.destination
            factory = storeFactory
            
        } else if let (findedViewController, findedFactory) = dependencyRouterFindSourceRouterViewController(segue.destination)  {
            viewController = findedViewController
            factory = findedFactory
            
        } else {
            return false
        }
        
        //3. Setup
        DependencyRouterError.tryAsFatalError {
            try factory.findAndSetup(viewController, sourceList: sourceList, identifier: segue.identifier, sender: sender)
        }
        
        return true
    }
    
    
    // MARK: - Private
    private class Store {
        var factory: (()->FactorySupportInputSource)?
        weak var weakSource: (AnyObject & BaseFactoryInputSource)?
        var sourceList: [BaseFactoryInputSource] = []
        var onlyOne: Bool = false
    }
    
    private var mapSegues: [String: Store] = [:]
}
