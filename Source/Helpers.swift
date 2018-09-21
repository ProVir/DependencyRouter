//
//  Helpers.swift
//  DependencyRouter
//
//  Created by Короткий Виталий on 19.09.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import UIKit

extension Router {
    @discardableResult
    public static func dismiss(_ viewController: UIViewController, animated: Bool = true) -> Bool {
        if let navigationController = viewController.navigationController {
            //Test to first in NavigationController
            if navigationController.viewControllers.first == viewController {
                if let pvc = navigationController.presentingViewController {
                    pvc.dismiss(animated: animated, completion: nil)
                    return true
                }
            }

            //Test to last in NavigationController
            else if navigationController.viewControllers.last == viewController {
                navigationController.popViewController(animated: animated)
                return true
            }

            //Test to center in NavigationController
            else if let indexVC = navigationController.viewControllers.index(where: { $0 === viewController }), indexVC > 0 {
                let prevVC = navigationController.viewControllers[indexVC-1]
                navigationController.popToViewController(prevVC, animated: animated)

                return true
            }
        }

        //Test to Modal
        if let pvc = viewController.presentingViewController {
            pvc.dismiss(animated: animated, completion: nil)
            return true
        }

        return false
    }
}

