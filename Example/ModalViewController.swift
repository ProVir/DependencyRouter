//
//  ModalViewController.swift
//  Example
//
//  Created by Короткий Виталий on 09.09.2018.
//  Copyright © 2018 ProVir. All rights reserved.
//

import UIKit
import DependencyRouter

struct ModalViewControllerFactory: LightFactoryRouter, CreatorFactoryRouter, BlankFactoryRouter {
    
    func defaultPresentation() -> PresentationRouter {
        return ModalPresentationRouter(autoWrapped: true, prepareHandler: nil)
    }
    
    func createViewController() -> ModalViewController {
        return createViewController(storyboardName: "Main", identifier: "modalContent")
    }
    
    func setupViewController(_ viewController: ModalViewController) {
        
    }
}

class ModalViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        
    }
    
    
    @IBAction func actionNext() {
        
        
    }
    
    
    @IBAction func actionModal() {
        
        
    }


}
