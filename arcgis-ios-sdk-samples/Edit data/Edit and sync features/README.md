# Edit and sync features

Synchronize offline edits with a feature service.

![Edit and sync features](edit-and-sync-features.png)

## Use case

A survey worker who works in an area without an internet connection could take a geodatabase of survey features offline at their office, make edits and add new features to the offline geodatabase in the field, and sync the updates with the online feature service after returning to the office.

## How to use the sample

Pan and zoom to position the red rectangle around the area to be taken offline. Tap "Generate geodatabase" to take the area offline. To edit features, tap to select a feature, and tap again anywhere else on the map to move the selected feature to the tapped location. To sync the edits with the feature service, tap the "Sync geodatabase" button.

## How it works

1. Create an `AGSGeodatabaseSyncTask` from a URL to a feature service.
2. Generate the geodatabase sync task with default parameters using `AGSGeodatabaseSyncTask.defaultGenerateGeodatabaseParameters(withExtent:completion:)`.
3. Create an `AGSGenerateGeodatabaseJob` object using `AGSGeodatabaseSyncTask.generateJob(with:downloadFileURL:)`, passing in the parameters and a path to where the geodatabase should be downloaded locally.
4. Start the job and get a geodatabase as a result.
5. Set the sync direction to `.bidirectional`.
6. To enable editing, load the geodatabase and get its feature tables. Create feature layers from the feature tables and add them to the map's operational layers collection.
7. Create an `AGSSyncGeodatabaseJob` object using `AGSGeodatabaseSyncTask.syncJob(with:geodatabase:)`, passing in the parameters and geodatabase as arguments.
8. Start the sync job to synchronize the edits.

## Relevant API

* AGSFeatureLayer
* AGSFeatureTable
* AGSGenerateGeodatabaseJob
* AGSGenerateGeodatabaseParameters
* AGSGeodatabaseSyncTask
* AGSSyncGeodatabaseJob
* AGSSyncGeodatabaseParameters
* AGSSyncLayerOption

## Offline data

This sample uses a [San Francisco offline basemap tile package](https://www.arcgis.com/home/item.html?id=e4a398afe9a945f3b0f4dca1e4faccb5).

## About the data

The basemap uses an offline tile package of San Francisco. The online feature service has features with wildfire information.

## Tags

feature service, geodatabase, offline, synchronize
