//
//  ThirdViewController.swift
//  Example
//
//  Created by Короткий Виталий on 03/10/2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import UIKit
import DependencyRouter

struct ThirdViewControllerFactory: LightBlankCreatorFactoryRouter {
    func presentationAction() -> PresentationAction {
        return ModalPresentationAction(autoWrapper: .system)
    }
    
    func createAndSetupViewController() -> ThirdViewController {
        return createViewControllerFromNib()
    }
}

class ThirdViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let closeItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(actionClose))
        navigationItem.leftBarButtonItem = closeItem
    }
    
    @IBAction func actionClose() {
        Router.dismiss(self)
    }

}
