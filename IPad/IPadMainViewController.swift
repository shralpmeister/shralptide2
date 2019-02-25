//
//  IPadMainViewController.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 11/22/18.
//

import Foundation

class IPadMainViewController: UIViewController {
    fileprivate let monthDateFormatter = DateFormatter()
    
    @IBOutlet fileprivate weak var collectionView: UICollectionView!
    @IBOutlet fileprivate weak var chartView: InteractiveChartView!
    @IBOutlet fileprivate weak var heightLabel: UILabel!
    @IBOutlet fileprivate weak var dateLabel: UILabel!
    @IBOutlet fileprivate weak var heightView: UIView!
    @IBOutlet fileprivate weak var informationOverlay: UIView!
    @IBOutlet fileprivate weak var editButton: UIBarButtonItem!
    
    fileprivate let app: ShralpTideAppDelegate = UIApplication.shared.delegate as! ShralpTideAppDelegate
    fileprivate var tideData: [SingleDayTideModel] = [SingleDayTideModel]()
    fileprivate var displayMonth = Calendar.current.component(.month, from: Date())
    fileprivate var displayYear = Calendar.current.component(.year, from: Date())
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    fileprivate func monthYearString() -> String {
        let date = Calendar.current.date(from: DateComponents(year: displayYear, month: displayMonth))!
        monthDateFormatter.setLocalizedDateFormatFromTemplate("MMMM YYYY")
        return monthDateFormatter.string(from: date)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        refreshTideData()
        
        app.supportedOrientations = .allButUpsideDown
        
        dateLabel.text = DateFormatter.localizedString(from: tideDataToChart.startTime, dateStyle: .long, timeStyle: .none)
        
        heightView.layer.cornerRadius = 5
        heightView.layer.masksToBounds = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(refreshTideData), name: .sdApplicationActivated, object: nil)
    }
    
    @objc func refreshTideData() {
        self.navigationItem.title = self.tideDataToChart.shortLocationName
        let tides = CalendarTideFactory.createTides(forYear: displayYear, month: displayMonth)
        self.tideData = tides.map { SingleDayTideModel(tide: $0) }
        
        collectionView.reloadData()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView.reloadData()
    }
    
    @IBAction func displayFavoritesPopover() {
        let storyboard = UIStoryboard(name: "iPadMain", bundle: nil)
        let locationsVC = storyboard.instantiateViewController(withIdentifier: "locationListController") as! FavoritesListViewController
        locationsVC.modalPresentationStyle = .popover
        locationsVC.popoverPresentationController!.barButtonItem = editButton
        locationsVC.popoverPresentationController!.delegate = self
        
        present(locationsVC, animated: true, completion: nil)
    }
}

// Collection view data source
extension IPadMainViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.item {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CurrentTideView", for: indexPath) as! CurrentTideCell
            cell.refresh(tide: app.tides[AppStateData.sharedInstance.locationPage])
            return cell
        case 1:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChartViewCell", for: indexPath) as! ChartViewCell
            if let layout = collectionView.layoutAttributesForItem(at: indexPath) {
                chartView.height = Int(layout.bounds.size.height * 3/4)
                chartView.frame = layout.bounds
                informationOverlay.superview!.frame = layout.bounds
            }
            cell.contentView.addSubview(chartView)
            chartView.addSubview(informationOverlay.superview!)
            chartView.setNeedsDisplay()
            return cell
        case 2:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CalendarHeader", for: indexPath) as! CalendarHeader
            cell.monthLabel.text = monthYearString()
            return cell
        default:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CalendarViewCell", for: indexPath) as! CalendarViewCell
            cell.displayedMonth = displayMonth
            cell.displayYear = displayYear
            cell.tides = self.tideData
            cell.layoutIfNeeded()
            cell.collectionView.reloadData()
            return cell
        }
    }
}

extension IPadMainViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch indexPath.item {
        case 0:
            return CGSize(width: getTideInfoWidth(collectionView), height: 275)
        case 1:
            return CGSize(width: getTideGraphWidth(collectionView), height: 275)
        case 2:
            return CGSize(width: collectionView.frame.size.width, height: 46)
        default:
            return CGSize(width: collectionView.frame.size.width, height: collectionView.frame.size.height - (275 + 60) )
        }
    }
}

extension IPadMainViewController: ChartViewDatasource {
    var tideDataToChart: SDTide! {
        return app.tides[AppStateData.sharedInstance.locationPage]
    }
    
    var day: Date! {
        return Date().startOfDay()
    }
    
    var page: Int32 {
        return 0
    }
}

extension IPadMainViewController: InteractiveChartViewDelegate {
    func displayHeight(_ height: CGFloat, atTime time: Date!, withUnitString units: String!) {
        UIView.beginAnimations("displayHeightAnimation", context: nil)
        self.heightView.alpha = 1.0
        self.heightLabel.text = String(format: "%0.2f %@ @ %@", height, units, DateFormatter.localizedString(from: time as Date, dateStyle: .none, timeStyle: .short))
        UIView.commitAnimations()
    }
    
    func interactionsEnded() {
        UIView.beginAnimations("displayHeightAnimation", context: nil)
        self.heightView.alpha = 0.0;
        UIView.commitAnimations()
    }
}

extension IPadMainViewController: UIPopoverPresentationControllerDelegate {
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        self.refreshTideData()
    }
}

extension IPadMainViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tideDataToChart.events.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let event = tideDataToChart.events[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "tideEventCell") as! SDTideEventCell
        cell.heightLabel.text = String.tideFormatString(value: event.eventHeight)
        cell.timeLabel.text = String.localizedTime(tideEvent: event)
        cell.typeLabel.text = event.eventType == .max ? "High" : "Low"
        return cell
    }
}

func getTideInfoWidth(_ collectionView: UICollectionView) -> CGFloat {
    let containerWidth = collectionView.frame.size.width
    return (containerWidth / 3) - 5
}

func getTideGraphWidth(_ collectionView: UICollectionView) -> CGFloat {
    let containerWidth = collectionView.frame.size.width
    return (containerWidth * 2 / 3) - 5
}
