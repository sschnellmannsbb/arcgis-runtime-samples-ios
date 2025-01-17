// Copyright 2017 Esri.
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

import ArcGIS

class RasterLayerGPKGViewController: UIViewController {
    @IBOutlet weak var mapView: AGSMapView!
    
    var geoPackage: AGSGeoPackage?

    override func viewDidLoad() {
        super.viewDidLoad()

        // add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["RasterLayerGPKGViewController"]
        
        // Instantiate a map.
        let map = AGSMap(basemapStyle: .arcGISLightGrayBase)
        
        // Create a geopackage from a named bundle resource.
        geoPackage = AGSGeoPackage(name: "AuroraCO")
        
        // Load the geopackage.
        geoPackage?.load { [weak self] error in
            guard error == nil else {
                self?.presentAlert(message: "Error opening Geopackage: \(error!.localizedDescription)")
                return
            }
            
            // Add the first raster from the geopackage to the map.
            if let raster = self?.geoPackage?.geoPackageRasters.first {
                let rasterLayer = AGSRasterLayer(raster: raster)
                // make it semi-transparent so it doesn't obscure the contents under it
                rasterLayer.opacity = 0.55
                map.operationalLayers.add(rasterLayer)
            }
        }
        
        // Display the map in the map view.
        mapView.map = map
        mapView.setViewpoint(AGSViewpoint(latitude: 39.7294, longitude: -104.8319, scale: 288895.277144))
    }
}
