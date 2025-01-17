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

import UIKit
import ArcGIS

class ExportTilesViewController: UIViewController {
    // MARK: Storyboard views
    
    /// The map view managed by the view controller.
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap(basemap: AGSBasemap(baseLayer: tiledLayer))
            // Set the min scale of the map to avoid requesting a huge download.
            let scale = 1e7
            mapView.map?.minScale = scale
            let center = AGSPoint(x: -117, y: 34, spatialReference: .wgs84())
            mapView.setViewpoint(AGSViewpoint(center: center, scale: scale), completion: nil)
        }
    }
    
    /// A view to emphasize the extent of exported tile layer.
    @IBOutlet var extentView: UIView! {
        didSet {
            extentView.layer.borderColor = UIColor.red.cgColor
            extentView.layer.borderWidth = 2
        }
    }
    
    /// A view to provide a dark blurry background to preview the exported tiles.
    @IBOutlet var visualEffectView: UIVisualEffectView!
    /// A map view to preview the exported tiles.
    @IBOutlet var previewMapView: AGSMapView! {
        didSet {
            previewMapView.layer.borderColor = UIColor.white.cgColor
            previewMapView.layer.borderWidth = 8
        }
    }
    /// A bar button to initiate the download task.
    @IBOutlet var exportTilesBarButtonItem: UIBarButtonItem!
    
    // MARK: Properties
    
    /// The tiled layer created from world street map service.
    let tiledLayer = AGSArcGISTiledLayer(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/World_Street_Map/MapServer")!)
    /// The export task to request the tile package with the same URL as the tile layer.
    let exportTask = AGSExportTileCacheTask(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/World_Street_Map/MapServer")!)
    /// An export job to download the tile package.
    var job: AGSExportTileCacheJob! {
        didSet {
            exportTilesBarButtonItem.isEnabled = job == nil ? true : false
        }
    }
    
    /// A URL to the temporary directory to temporarily store the exported tile package.
    let temporaryDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(ProcessInfo().globallyUniqueString)
    
    /// Tile Package storage formats.
    /// - Note: Please read more about the file formats at [here](https://github.com/Esri/tile-package-spec).
    private enum TilePackageFormat {
        case tpk, tpkx
        
        var description: String {
            switch self {
            case .tpk:
                return "Compact Cache V1 (.\(fileExtension))"
            case .tpkx:
                return "Compact Cache V2 (.\(fileExtension))"
            }
        }
        
        var fileExtension: String {
            switch self {
            case .tpk:
                return "tpk"
            case .tpkx:
                return "tpkx"
            }
        }
    }
    
    // MARK: Methods
    
    /// Initiate the `AGSExportTileCacheTask` to download a tile package.
    ///
    /// - Parameters:
    ///   - exportTask: An `AGSExportTileCacheTask` to run the export job.
    ///   - downloadFileURL: A URL to where the tile package should be saved.
    func initiateDownload(exportTask: AGSExportTileCacheTask, downloadFileURL: URL) {
        // Get the parameters by specifying the selected area, map view's
        // current scale as the minScale, and tiled layer's max scale as
        // maxScale.
        var minScale = mapView.mapScale
        let maxScale = tiledLayer.maxScale
        if minScale < maxScale {
            minScale = maxScale
        }
        
        // Get current area of interest marked by the extent view.
        let areaOfInterest = frameToExtent()
        // Get export parameters.
        exportTask.exportTileCacheParameters(withAreaOfInterest: areaOfInterest, minScale: minScale, maxScale: maxScale) { [weak self, unowned exportTask] (params: AGSExportTileCacheParameters?, error: Error?) in
            guard let self = self else { return }
            if let params = params {
                self.exportTiles(exportTask: exportTask, parameters: params, downloadFileURL: downloadFileURL)
            } else if let error = error {
                self.presentAlert(error: error)
            }
        }
    }
    
    /// Export tiles with the `AGSExportTileCacheJob` from the export task.
    ///
    /// - Parameters:
    ///   - exportTask: An `AGSExportTileCacheTask` to run the export job.
    ///   - parameters: The parameters of the export task.
    ///   - downloadFileURL: A URL to where the tile package is saved.
    func exportTiles(exportTask: AGSExportTileCacheTask, parameters: AGSExportTileCacheParameters, downloadFileURL: URL) {
        // Get and run the job.
        job = exportTask.exportTileCacheJob(with: parameters, downloadFileURL: downloadFileURL)
        job.start(statusHandler: { (status) in
            UIApplication.shared.showProgressHUD(message: status.statusString())
        }, completion: { [weak self] (result, error) in
            UIApplication.shared.hideProgressHUD()
            guard let self = self else { return }
            
            self.job = nil
            
            if let tileCache = result {
                self.visualEffectView.isHidden = false
                
                let newTiledLayer = AGSArcGISTiledLayer(tileCache: tileCache)
                self.previewMapView.map = AGSMap(basemap: AGSBasemap(baseLayer: newTiledLayer))
                let extent = parameters.areaOfInterest as! AGSEnvelope
                self.previewMapView.setViewpoint(AGSViewpoint(targetExtent: extent), completion: nil)
            } else if let error = error {
                if (error as NSError).code != NSUserCancelledError {
                    self.presentAlert(error: error)
                }
            }
        })
    }
    
    /// Get the extent within the extent view for generating a tile package.
    func frameToExtent() -> AGSEnvelope {
        let frame = mapView.convert(extentView.frame, from: self.view)
        
        let minPoint = mapView.screen(toLocation: CGPoint(x: frame.minX, y: frame.minY))
        let maxPoint = mapView.screen(toLocation: CGPoint(x: frame.maxX, y: frame.maxY))
        let extent = AGSEnvelope(min: minPoint, max: maxPoint)
        return extent
    }
    
    /// Make the destination URL for the tile package.
    private func makeDownloadURL(fileFormat: TilePackageFormat) -> URL {
        // If the downloadFileURL ends with ".tpk", the tile cache will use
        // the legacy compact format. If the downloadFileURL ends with ".tpkx",
        // the tile cache will use the current compact version 2 format.
        // See more in the doc of
        // `AGSExportTileCacheTask.exportTileCacheJob(with:downloadFileURL:)`.
        
        // Create the temp directory if it doesn't exist.
        try? FileManager.default.createDirectory(at: temporaryDirectoryURL, withIntermediateDirectories: true)
        return temporaryDirectoryURL
            .appendingPathComponent("myTileCache", isDirectory: false)
            .appendingPathExtension(fileFormat.fileExtension)
    }
    // MARK: Actions
    
    @IBAction func exportTilesBarButtonTapped(_ sender: UIBarButtonItem) {
        if let mapServiceInfo = exportTask.mapServiceInfo, mapServiceInfo.exportTilesAllowed {
            // Try to download when exporting tiles is allowed.
            let tilePackageFormat: TilePackageFormat
            if mapServiceInfo.exportTileCacheCompactV2Allowed {
                // Export using the CompactV2 (.tpkx) if it is supported.
                tilePackageFormat = .tpkx
            } else {
                // Otherwise, use the CompactV1 (.tpk) format.
                tilePackageFormat = .tpk
            }
            self.initiateDownload(exportTask: exportTask, downloadFileURL: makeDownloadURL(fileFormat: tilePackageFormat))
        } else {
            presentAlert(title: "Error", message: "Exporting tiles is not supported for the service.")
        }
    }
    
    @IBAction func closeButtonTapped(_ sender: UIButton) {
        // Hide the preview and background.
        visualEffectView.isHidden = true
        // Release the map in order to free the tiled layer.
        previewMapView.map = nil
        // Remove the sample-specific temporary directory and all content in it.
        try? FileManager.default.removeItem(at: temporaryDirectoryURL)
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ExportTilesViewController"]
        // Load the export task.
        exportTask.load { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else {
                self.exportTilesBarButtonItem.isEnabled = true
            }
        }
    }
    
    deinit {
        // Remove the temporary directory and all content in it.
        try? FileManager.default.removeItem(at: temporaryDirectoryURL)
    }
}
