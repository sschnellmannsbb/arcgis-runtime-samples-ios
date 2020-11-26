// Copyright 2016 Esri.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import ArcGIS

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {
    var window: UIWindow?
    
    var splitViewController: UISplitViewController {
        return window!.rootViewController as! UISplitViewController
    }
    var categoryBrowserViewController: ContentCollectionViewController {
        return (splitViewController.viewControllers.first as! UINavigationController).viewControllers.first as! ContentCollectionViewController
    }
 
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        if url.absoluteString.range(of: "auth", options: [], range: nil, locale: nil) != nil {
            AGSApplicationDelegate.shared().application(app, open: url, options: options)
        }
        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Override point for customization after application launch.
        let splitViewController = self.window!.rootViewController as! UISplitViewController
        splitViewController.presentsWithGesture = false
        splitViewController.preferredDisplayMode = .allVisible
        let navigationController = splitViewController.viewControllers.last as! UINavigationController
        navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        navigationController.topViewController!.navigationItem.leftItemsSupplementBackButton = true
        splitViewController.delegate = self
        
        //min max width for master
        splitViewController.minimumPrimaryColumnWidth = 320
        splitViewController.maximumPrimaryColumnWidth = 320
        
        // Decode and populate Categories.
        categoryBrowserViewController.categories = decodeCategories(at: contentPlistURL)
        
        self.modifyAppearance()
        
        // Enable/disable touches based on settings.
        self.setTouchPref()
        
        SVProgressHUD.setDefaultMaskType(.gradient)
        
        // Set license key with custom build rule.
        application.license()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        self.setTouchPref()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    // MARK: - Touch settings
    
    func setTouchPref() {
        //enable/disable touches based on settings
        let bool = UserDefaults.standard.bool(forKey: "showTouch")
        if bool {
            DemoTouchManager.shared.showTouches()
            DemoTouchManager.shared.touchBorderColor = .lightGray
            DemoTouchManager.shared.touchFillColor = UIColor(white: 231 / 255.0, alpha: 1)
        } else {
            DemoTouchManager.shared.hideTouches()
        }
    }
    
    // MARK: - Appearance modification
    
    func modifyAppearance() {
        let navigationBarAppearanceProxy = UINavigationBar.appearance()
        if #available(iOS 13.0, *) {
            let navigationBarAppearance = UINavigationBarAppearance()
            navigationBarAppearance.configureWithTransparentBackground()
            navigationBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
            navigationBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            navigationBarAppearance.backgroundColor = .accentColor
            
            navigationBarAppearanceProxy.standardAppearance = navigationBarAppearance
            navigationBarAppearanceProxy.compactAppearance = navigationBarAppearance
            navigationBarAppearanceProxy.scrollEdgeAppearance = navigationBarAppearance
        } else {
            navigationBarAppearanceProxy.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
            navigationBarAppearanceProxy.titleTextAttributes = [.foregroundColor: UIColor.white]
            navigationBarAppearanceProxy.barTintColor = .accentColor
        }
        UISwitch.appearance().onTintColor = .accentColor
        navigationBarAppearanceProxy.tintColor = .white
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = .accentColor
        if #available(iOS 14.0, *) {
            // Nothing to do! iOS 14 handles global tint with accent color.
        } else {
            // Override tint color for `UIControl`s.
            UIToolbar.appearance().tintColor = .accentColor
            UISlider.appearance().tintColor = .accentColor
            UITableViewCell.appearance().tintColor = .accentColor
            UIProgressView.appearance().tintColor = .accentColor
            UIButton.appearance(whenContainedInInstancesOf: [AGSCallout.self]).tintColor = .accentColor
        }
    }

    // MARK: - Split view

    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        if secondaryViewController.restorationIdentifier == "DetailNavigationController" {
            return true
        } else {
            return false
        }
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        if let navigationController = primaryViewController as? UINavigationController {
            if navigationController.topViewController! is ContentCollectionViewController || navigationController.topViewController is ContentTableViewController {
                let controller = splitViewController.storyboard!.instantiateViewController(withIdentifier: "DetailNavigationController") as! UINavigationController
                controller.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
                controller.topViewController!.navigationItem.leftItemsSupplementBackButton = true
                return controller
            }
        }
        return nil
    }
    
    // MARK: - Sample import
    
    /// The URL of the content plist file inside the bundle.
    private var contentPlistURL: URL {
        return Bundle.main.url(forResource: "ContentPList", withExtension: "plist")!
    }
    
    /// Decodes an array of categories from the plist at the given URL.
    ///
    /// - Parameter url: The url of a plist that defines categories.
    /// - Returns: An array of categories.
    private func decodeCategories(at url: URL) -> [Category] {
        do {
            let data = try Data(contentsOf: url)
            return try PropertyListDecoder().decode([Category].self, from: data)
        } catch {
            fatalError("Error decoding categories at \(url): \(error)")
        }
    }
}

extension UIColor {
    // Also used as global tint/accent color.
    class var accentColor: UIColor { return UIColor(named: "AccentColor")! }
    // The translucent background color for status labels.
    class var statusLabelBackgroundColor: UIColor { return UIColor(named: "statusLabelBackgroundColor")! }
}

extension UIApplication {
    /// License the app with ArcGIS Runtime deployment license keys.
    ///
    /// - Note: An invalid key does not throw an exception, but simply fails to license the app,
    ///   falling back to Developer Mode (which will display a watermark on the map view).
    func license() {
        do {
            // Don't set extension key if you don't use utility network samples.
            // try AGSArcGISRuntimeEnvironment.setLicenseKey(.licenseKey)
            
            // Set both keys for accessing all samples.
            try AGSArcGISRuntimeEnvironment.setLicenseKey(.licenseKey, extensions: [.extensionLicenseKey])
            
            // Set API keys for new metered basemap styles.
            // AGSArcGISRuntimeEnvironment.apiKey = .apiKey
        } catch {
            print("[Error: AGSArcGISRuntimeEnvironment] Error licensing app: \(error.localizedDescription)")
        }
        print("[ArcGIS Runtime License] \(AGSArcGISRuntimeEnvironment.license())")
    }
}
