//
//  StationMap.swift
//  SwiftTides
//
//  Created by Michael Parlee on 1/15/21.
//

import SwiftUI
import MapKit
import ShralpTideFramework

private let annotationViewReuseIdentifier = "TideStationMarkerView"

struct StationMapView: UIViewRepresentable {
  @EnvironmentObject private var config: ConfigHelper

  @Binding var centerCoordinate: CLLocationCoordinate2D
  @Binding var showingDetail: Bool
  @Binding var selectedLocation: TideAnnotation
  @Binding var detailMapRegion: MKCoordinateRegion
  
  @State var annotations: [TideAnnotation] = []
  
  private var locationManager = CLLocationManager()
  
  init(
    centerCoordinate: Binding<CLLocationCoordinate2D>,
    showingDetail: Binding<Bool>,
    selectedLocation: Binding<TideAnnotation>,
    detailMapRegion: Binding<MKCoordinateRegion>
  ) {
    self._centerCoordinate = centerCoordinate
    self._showingDetail = showingDetail
    self._selectedLocation = selectedLocation
    self._detailMapRegion = detailMapRegion
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
    let oldRegionSet = view.annotations.reduce(into: Set<TideAnnotation>(), { (set, annot) in
      if let pointAnnotation = annot as? TideAnnotation {
        set.insert(pointAnnotation)
      }
    })
    let newRegionSet = Set(self.annotations)
    
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
  
  class Coordinator: NSObject, MKMapViewDelegate {
    @Environment(\.legacyStationInteractor) private var legacyInteractor: TideStationInteractor
    @Environment(\.stationInteractor) private var interactor: TideStationInteractor
    
    var parent: StationMapView

    init(_ parent: StationMapView) {
        self.parent = parent
    }
    
    private func getStations(in region:MKCoordinateRegion) -> [SDTideStation] {
      if parent.config.settings.legacyMode {
        return legacyInteractor.tideStations(in: region)
      } else {
        return interactor.tideStations(in: region)
      }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
      parent.centerCoordinate = mapView.centerCoordinate
      
      parent.annotations = getStations(in: mapView.region).map { (station: SDTideStation) in
        let annotation = TideAnnotation()
        annotation.title = station.name
        annotation.coordinate = CLLocationCoordinate2D(latitude: Double(truncating: station.latitude!), longitude: Double(truncating: station.longitude!))
        annotation.isPrimary = station.primary?.boolValue ?? false
        return annotation
      }
      print("Visible region update: \(parent.annotations.count)")
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
      var region = MKCoordinateRegion()
      region.center = userLocation.coordinate
      region.span.longitudeDelta = 0.5
      region.span.latitudeDelta = 0.5
      mapView.region = region
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
      if annotation as? MKUserLocation != nil {
        return nil
      }
      var view: MKMarkerAnnotationView? = mapView.dequeueReusableAnnotationView(withIdentifier: annotationViewReuseIdentifier) as? MKMarkerAnnotationView
      if view == nil {
        view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: annotationViewReuseIdentifier)
      } else {
        view!.annotation = annotation
      }
      view?.canShowCallout = true
      let button = UIButton(type: .detailDisclosure, primaryAction: UIAction(handler: { action in
        print("Selected station! \(String(describing: annotation))")
        self.parent.selectedLocation = annotation as! TideAnnotation
        self.parent.showingDetail = true
      }))
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
