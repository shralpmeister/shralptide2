//
//  PortraitViewController.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 11/18/18.
//

import Foundation

@objc class PortraitViewController: UIViewController, UIAdaptivePresentationControllerDelegate {
    @IBOutlet fileprivate weak var listViewButton: UIButton!

    fileprivate var headerViewController: CurrentTideViewController!
    fileprivate var bottomViewController: SDBottomViewController!
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.children.forEach { controller in
            switch (controller.restorationIdentifier) {
            case "HeaderViewController":
                self.headerViewController = controller as? CurrentTideViewController
            case "MainViewController":
                self.bottomViewController = controller as? SDBottomViewController
            default:
                print("Unknown child view: \(String(describing: controller.restorationIdentifier))")
            }
        }
        if (self.view.isKind(of: UIImageView.self)) {
            let imageView = self.view as! UIImageView
            imageView.image = UIImage(named: "background-gradient")
            imageView.contentMode = UIImageView.ContentMode.scaleToFill
        }
        listViewButton.imageView?.image = listViewButton.imageView?.image?.maskImage(with: UIColor(white: 0.8, alpha: 1))
        
        NotificationCenter.default.addObserver(self, selector: #selector(refreshTideData), name: .sdApplicationActivated, object: nil)
        
        let app = UIApplication.shared.delegate as! ShralpTideAppDelegate
        app.supportedOrientations = .allButUpsideDown
    }
    
    @objc func refreshTideData() {
        let app = UIApplication.shared.delegate as! ShralpTideAppDelegate
        self.bottomViewController.createPages(app.tides?[AppStateData.sharedInstance.locationPage])
        self.headerViewController.refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshTideData()
    }
    
    func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .lightContent
    }
    
    //MARK: Handle orientation changes
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(
            alongsideTransition: { (_: UIViewControllerTransitionCoordinatorContext) in
                self.handleInterfaceOrientation()
            },
            completion: { (_: UIViewControllerTransitionCoordinatorContext) in
            }
        )
    }
    
    fileprivate func handleInterfaceOrientation() {
        if ([.landscapeLeft, .landscapeRight].contains(UIApplication.shared.statusBarOrientation)) {
            self.performSegue(withIdentifier: "landscapeSegue", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "locationMainViewSegue") {
            bottomViewController = (segue.destination as! SDBottomViewController)
        } else if (segue.identifier == "landscapeSegue") {
            let landscapeController = segue.destination as! LandscapeViewController
            landscapeController.bottomViewController = bottomViewController
        } else if (segue.identifier == "FavoritesListSegue") {
            let favoritesController = segue.destination as! FavoritesListViewController
            favoritesController.portraitViewController = self
            favoritesController.presentationController?.delegate = self
        } else {
            print("Unexpected transition \(String(describing: segue.identifier))")
        }
    }
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.viewWillAppear(true)
    }
}
