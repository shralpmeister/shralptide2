//
//  StationMap.swift
//  SwiftTides
//
//  Created by Michael Parlee on 1/15/21.
//

import MapKit
import ShralpTideFramework
import SwiftUI

private let annotationViewReuseIdentifier = "TideStationMarkerView"

struct StationMapView: UIViewRepresentable {
    @EnvironmentObject private var config: ConfigHelper
    
    @Environment(\.legacyStationInteractor) private var legacyInteractor: TideStationInteractor
    @Environment(\.stationInteractor) private var interactor: TideStationInteractor

    @Binding var stationType: StationType
    @Binding var centerCoordinate: CLLocationCoordinate2D
    @Binding var showingDetail: Bool
    @Binding var selectedLocation: TideAnnotation
    @Binding var detailMapRegion: MKCoordinateRegion

    @State var tideStations: [TideAnnotation] = []
    @State var currentStations: [TideAnnotation] = []

    private var locationManager = CLLocationManager()

    init(
        centerCoordinate: Binding<CLLocationCoordinate2D>,
        showingDetail: Binding<Bool>,
        selectedLocation: Binding<TideAnnotation>,
        detailMapRegion: Binding<MKCoordinateRegion>,
        stationType: Binding<StationType>
    ) {
        _centerCoordinate = centerCoordinate
        _showingDetail = showingDetail
        _selectedLocation = selectedLocation
        _detailMapRegion = detailMapRegion
        _stationType = stationType
    }

    func makeUIView(context: Context) -> MKMapView {
        locationManager.requestWhenInUseAuthorization()
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ view: MKMapView, context: Context) {
        // Need to filter to remove other annotation types in the view (MKUserLocation)
        let oldRegionSet = view.annotations.reduce(into: Set<TideAnnotation>()) { set, annot in
            if let pointAnnotation = annot as? TideAnnotation {
                set.insert(pointAnnotation)
            }
        }
        
        let newRegionSet = Set(stationType == .tides ? tideStations : currentStations)

        let keeperAnnotations = oldRegionSet.intersection(newRegionSet)
        let loserAnnotations = oldRegionSet.subtracting(keeperAnnotations)
        let newAnnotations = newRegionSet.subtracting(keeperAnnotations)

        view.removeAnnotations(Array(loserAnnotations))
        view.addAnnotations(Array(newAnnotations))
        print("Added \(newAnnotations.count) stations")
        print("Removed \(loserAnnotations.count) stations")
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func getStations(in region: MKCoordinateRegion) -> [SDTideStation] {
        if config.settings.legacyMode {
            return legacyInteractor.tideStations(in: region)
        } else {
            return interactor.tideStations(in: region)
        }
    }
    
    private func getCurrentStations(in region: MKCoordinateRegion) -> [SDTideStation] {
        if config.settings.legacyMode {
            return legacyInteractor.currentStations(in: region)
        } else {
            return interactor.currentStations(in: region)
        }
    }
    
    func getStationAnnotations(for region: MKCoordinateRegion) -> [TideAnnotation] {
        return getStations(in: region).map { (station: SDTideStation) in
            let annotation = TideAnnotation()
            annotation.title = station.name
            annotation.coordinate = CLLocationCoordinate2D(
                latitude: Double(truncating: station.latitude!),
                longitude: Double(truncating: station.longitude!)
            )
            annotation.isPrimary = station.primary?.boolValue ?? false
            return annotation
        }
    }
    
    func getCurrentAnnotations(for region: MKCoordinateRegion) -> [TideAnnotation] {
        return getCurrentStations(in: region).map { (station: SDTideStation) in
            let annotation = TideAnnotation()
            annotation.title = station.name
            annotation.coordinate = CLLocationCoordinate2D(
                latitude: Double(truncating: station.latitude!),
                longitude: Double(truncating: station.longitude!)
            )
            annotation.isPrimary = station.primary?.boolValue ?? false
            return annotation
        }
    }
    class Coordinator: NSObject, MKMapViewDelegate {

        var region: MKCoordinateRegion?

        var parent: StationMapView

        init(_ parent: StationMapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated _: Bool) {
            parent.centerCoordinate = mapView.centerCoordinate
            parent.tideStations = parent.getStationAnnotations(for: mapView.region)
            if parent.config.settings.showsCurrentsPref {
                parent.currentStations = parent.getCurrentAnnotations(for: mapView.region)
            }
            print("Visible region update: \(parent.tideStations.count)")
        }

        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            if region == nil {
                region = MKCoordinateRegion()
                region?.center = userLocation.coordinate
                region?.span.longitudeDelta = 0.5
                region?.span.latitudeDelta = 0.5
                mapView.region = region!
            }
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation as? MKUserLocation != nil {
                return nil
            }
            var view: MKMarkerAnnotationView? =
                mapView.dequeueReusableAnnotationView(withIdentifier: annotationViewReuseIdentifier)
                    as? MKMarkerAnnotationView
            if view == nil {
                view = MKMarkerAnnotationView(
                    annotation: annotation, reuseIdentifier: annotationViewReuseIdentifier
                )
            } else {
                view!.annotation = annotation
            }
            view?.canShowCallout = true
            let button = UIButton(
                type: .detailDisclosure,
                primaryAction: UIAction(handler: { _ in
                    print("Selected station! \(String(describing: annotation))")
                    self.parent.selectedLocation = annotation as! TideAnnotation
                    self.parent.showingDetail = true
                })
            )
            view?.rightCalloutAccessoryView = button
            if let tideAnnotation = annotation as? TideAnnotation {
                if tideAnnotation.isPrimary {
                    view!.displayPriority = .required
                    view!.markerTintColor = UIColor.systemGreen
                } else {
                    view!.displayPriority = .defaultLow
                }
            }
            return view
        }
    }
}
