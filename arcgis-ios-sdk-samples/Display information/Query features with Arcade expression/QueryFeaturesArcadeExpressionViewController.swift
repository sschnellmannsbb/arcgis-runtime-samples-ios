// Copyright 2021 Esri
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import ArcGIS

class QueryFeaturesArcadeExpressionViewController: UIViewController {
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
            // Set the touch delegate.
            mapView.touchDelegate = self
        }
    }
    
    /// The arcade expression evaluation operation.
    var evaluateOperation: AGSCancelable?
    
    /// Make and load a map.
    func makeMap() -> AGSMap {
        // Create a portal item with the portal and item ID.
        let portalItem = AGSPortalItem(portal: .arcGISOnline(withLoginRequired: false), itemID: "14562fced3474190b52d315bc19127f6")
        // Make a map with the portal item.
        let map = AGSMap(item: portalItem)
        // Load the map.
        map.load() { _ in
            // Set the visibility of all but the RDT Beats layer to false.
            map.operationalLayers.forEach { layer in
                let currentLayer = layer as? AGSLayer
                if currentLayer?.name == "Crime in the last 60 days" || currentLayer?.name == "Police Stations" {
                    currentLayer?.isVisible = false
                }
            }
        }
        return map
    }
    
    /// Evaluate the arcade expression for the selected feature at the map point.
    func evaluateArcadeInCallout(for feature: AGSArcGISFeature, at mapPoint: AGSPoint) {
        // Instantiate a string containing the arcade expression.
        let expressionValue = "var crimes = FeatureSetByName($map, 'Crime in the last 60 days');\n" + "return Count(Intersects($feature, crimes));"
        // Create an arcade expression using the string.
        let expression = AGSArcadeExpression(expression: expressionValue)
        // Create an arcade evaluator with the arcade expression and an arcade profile.
        let evaluator = AGSArcadeEvaluator(expression: expression, profile: .formCalculation)
        guard let map = mapView.map else { return }
        let profileVariables = ["$feature": feature, "$map": map]
        // Get the arcade evaluation result given the previously set profile variables.
        evaluateOperation = evaluator.evaluate(withProfileVariables: profileVariables) { [weak self] result, error in
            guard let self = self else { return }
            if let result = result, let crimeCount = result.cast(to: .string) as? String {
                // Dismiss progress hud.
                UIApplication.shared.hideProgressHUD()
                // Hide the accessory button.
                self.mapView.callout.isAccessoryButtonHidden = true
                // Set the detail text.
                self.mapView.callout.detail = "Crimes in the last 60 days: \(crimeCount)"
                // Prompt the callout at the map point.
                self.mapView.callout.show(at: mapPoint, screenOffset: .zero, rotateOffsetWithMap: false, animated: true)
            } else if let error = error {
                // Present an error if needed.
                self.presentAlert(error: error)
            }
        }
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = [
            "QueryFeaturesArcadeExpressionViewController"
        ]
    }
}

// MARK: - AGSGeoViewTouchDelegate

extension QueryFeaturesArcadeExpressionViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // Dismiss any presenting callout.
        mapView.callout.dismiss()
        // Identify features at the tapped location.
        mapView.identifyLayers(atScreenPoint: screenPoint, tolerance: 12, returnPopupsOnly: false) { [weak self] results, error in
            guard let results = results, let self = self else { return }
            if let elements = results.first?.geoElements {
                // Get the selected feature.
                guard let identifiedFeature = elements.first as? AGSArcGISFeature else { return }
                // Show progress hud.
                UIApplication.shared.showProgressHUD(message: "Evaluating")
                // Evaluate the arcade for the given feature.
                self.evaluateArcadeInCallout(for: identifiedFeature, at: mapPoint)
            } else if let error = error {
                // Present an error alert if needed.
                self.presentAlert(error: error)
            }
        }
    }
}
