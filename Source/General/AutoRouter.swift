//
//  AutoRouter.swift
//  DependencyRouter
//
//  Created by Короткий Виталий on 16.09.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import Foundation


//MARK: Auto Setup from viewDidLoad
public protocol AutoRouterViewController: SourceRouterViewController where Factory: BlankFactoryRouter {
    var setupedByRouter: Bool { get }
}

extension Router {
    public static func viewDidLoad<VC: AutoRouterViewController>(_ viewController: VC) where VC == VC.Factory.VCType {
        setupIfNeed(viewController)
    }
    
    public static func setupIfNeed<VC: AutoRouterViewController>(_ viewController: VC) where VC == VC.Factory.VCType {
        if viewController.setupedByRouter { return }
        
        let factory = viewController.createFactoryForSetup()
        factory.setupViewController(viewController)
        
        if viewController.setupedByRouter == false {
            DependencyRouterError.failureSetupViewController.assertionFailure()
        }
    }
    
    public static func setupIfNeed<FR: BlankFactoryRouter>(_ needSetup: Bool, factory: @autoclosure ()->FR, viewController: FR.VCType) {
        if needSetup {
            let use_factory = factory()
            use_factory.setupViewController(viewController)
        }
    }
}

