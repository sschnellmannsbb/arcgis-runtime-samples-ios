# Feature layer query

Find features in a feature table which match an SQL query.

![Feature layer query options](feature-layer-query-1.png)
![Feature layer query results](feature-layer-query-2.png)

## Use case

Query expressions can be used in ArcGIS to select a subset of features from a feature table. This is most useful in large or complicated data sets. A possible use case might be on a feature table marking the location of street furniture through a city. A user may wish to query by a TYPE column to return "benches". In this sample, we query a U.S. state by STATE_NAME from a feature table containing all U.S. states.

## How to use the sample

Input the name of a U.S. state into the text field. A query is performed and the matching features are highlighted or an error is returned.

## How it works

1. Create an `AGSServiceFeatureTable` using the URL of a feature service.
2. Create `AGSQueryParameters` with a `whereClause` specified.
3. Perform the query using `AGSFeatureTable.queryFeatures(with:completion:)` on the service feature table.
4. When complete, the query will return an `AGSFeatureQueryResult` which can be iterated over to get the matching features.

## Relevant API

* AGSFeatureLayer
* AGSFeatureQueryResult
* AGSQueryParameters
* AGSServiceFeatureTable

## About the data

This sample uses U.S. State polygon features from the [USA 2016 Daytime Population](https://www.arcgis.com/home/item.html?id=f01f0eda766344e29f42031e7bfb7d04) feature service.

## Tags

query, search
