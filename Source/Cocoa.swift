//
//  Cocoa.swift
//  DependencyRouter
//
//  Created by Короткий Виталий on 08.09.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import UIKit



//MARK: Containers
extension UINavigationController: ViewContainerSupportRouter {
    public func findViewController<VCType>() -> VCType? {
        if let vc = viewControllers.first as? VCType {
            return vc
        } else if let container = viewControllers.first as? ViewContainerSupportRouter {
            return container.findViewController()
        } else {
            return nil
        }
    }
}

