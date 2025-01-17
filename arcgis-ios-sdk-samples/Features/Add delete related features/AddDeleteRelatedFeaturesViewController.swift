//
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
//

import UIKit
import ArcGIS

class AddDeleteRelatedFeaturesViewController: UIViewController, AGSGeoViewTouchDelegate {
    @IBOutlet var mapView: AGSMapView!
    
    private var parksFeatureTable: AGSServiceFeatureTable!
    private var parksFeatureLayer: AGSFeatureLayer!
    
    private var selectedPark: AGSFeature!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["AddDeleteRelatedFeaturesViewController", "RelatedFeaturesViewController"]

        // initialize map with basemap
        let map = AGSMap(basemapStyle: .arcGISStreets)
        
        // initial viewpoint
        let point = AGSPoint(x: -16507762.575543, y: 9058828.127243, spatialReference: .webMercator())
        
        // parks feature table
        self.parksFeatureTable = AGSServiceFeatureTable(url: URL(string: "https://services2.arcgis.com/ZQgQTuoyBrtmoGdP/ArcGIS/rest/services/AlaskaNationalParksSpecies_Add_Delete/FeatureServer/0")!)
        
        // parks feature layer
        let parksFeatureLayer = AGSFeatureLayer(featureTable: self.parksFeatureTable)
        
        // add feature layer to the map
        map.operationalLayers.add(parksFeatureLayer)
        
        // species feature table (destination feature table)
        // related to the parks feature layer in a 1..M relationship
        let speciesFeatureTable = AGSServiceFeatureTable(url: URL(string: "https://services2.arcgis.com/ZQgQTuoyBrtmoGdP/ArcGIS/rest/services/AlaskaNationalParksSpecies_Add_Delete/FeatureServer/1")!)
        
        // add table to the map
        // for the related query to work, the related table should be present in the map
        map.tables.add(speciesFeatureTable)
        
        // assign map to map view
        mapView.map = map
        mapView.setViewpoint(AGSViewpoint(center: point, scale: 36764077))
        
        // set touch delegate
        mapView.touchDelegate = self
        
        // store the feature layer for later use
        self.parksFeatureLayer = parksFeatureLayer
    }
    
    // MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // show progress hud for identify
        UIApplication.shared.showProgressHUD(message: "Identifying feature")
        
        // identify features at tapped location
        self.mapView.identifyLayer(self.parksFeatureLayer, screenPoint: screenPoint, tolerance: 12, returnPopupsOnly: false) { [weak self] (result) in
            // hide progress hud
            UIApplication.shared.hideProgressHUD()
            
            if let error = result.error {
                // show error to user
                self?.presentAlert(error: error)
            } else if let feature = result.geoElements.first as? AGSFeature {
                // select the first feature
                self?.selectedPark = feature
                
                // show related features view controller
                self?.performSegue(withIdentifier: "RelatedFeaturesSegue", sender: self)
            }
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "RelatedFeaturesSegue",
            let navigationController = segue.destination as? UINavigationController,
            let controller = navigationController.viewControllers.first as? RelatedFeaturesViewController {
            // share selected park
            controller.originFeature = self.selectedPark as? AGSArcGISFeature
            
            // share parks feature table as origin feature table
            controller.originFeatureTable = self.parksFeatureTable
        }
    }
}
