//
//  Router.swift
//  Example
//
//  Created by Короткий Виталий on 16.09.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import Foundation




//MARK: Router
public struct Router {
    public static func viewDidLoad<FR: BlankFactoryRouter>(_ needSetup: Bool, factory: @autoclosure ()->FR, viewController: FR.VCType) {
        if needSetup {
            let use_factory = factory()
            use_factory.setupViewController(viewController)
        }
    }
    
    public static func viewDidLoad<VC: AutoRouterViewController>(_ viewController: VC) where VC == VC.Factory.VCType, VC.Factory.ContainerType: AutoServiceContainer {
        if viewController.setupedByRouter { return }
        
        let factory = viewController.createFactoryForSetup()
        factory.setupViewController(viewController)
        
        testIsSetuped(viewController)
    }
    
    private static func testIsSetuped<VC: AutoRouterViewController>(_ viewController: VC, file: StaticString = #file, line: UInt = #line) {
        if !viewController.setupedByRouter {
            DependencyRouterError.failureSetupViewController.assertionFailure(file: file, line: line)
        }
    }
}


