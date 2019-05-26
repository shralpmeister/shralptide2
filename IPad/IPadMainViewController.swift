//
//  IPadMainViewController.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 11/22/18.
//

import Foundation

class IPadMainViewController: UIViewController {
    fileprivate let monthDateFormatter = DateFormatter()
    
    // Month view and header
    @IBOutlet fileprivate weak var monthLabel: UILabel!
    @IBOutlet fileprivate weak var day0: UILabel!
    @IBOutlet fileprivate weak var day1: UILabel!
    @IBOutlet fileprivate weak var day2: UILabel!
    @IBOutlet fileprivate weak var day3: UILabel!
    @IBOutlet fileprivate weak var day4: UILabel!
    @IBOutlet fileprivate weak var day5: UILabel!
    @IBOutlet fileprivate weak var day6: UILabel!
    @IBOutlet fileprivate weak var collectionView: UICollectionView!
    @IBOutlet fileprivate weak var resetButton: UIButton!
    @IBOutlet fileprivate weak var prevButton: UIButton!
    @IBOutlet fileprivate weak var nextButton: UIButton!
    
    // current conditions
    @IBOutlet fileprivate weak var currentTideView: UIView!
    @IBOutlet fileprivate weak var currentDate: UILabel!
    @IBOutlet fileprivate weak var currentLevel: UILabel!
    @IBOutlet fileprivate weak var eventsTable: UITableView!
    
    // chart view
    @IBOutlet fileprivate weak var chartView: InteractiveChartView!
    @IBOutlet fileprivate weak var heightLabel: UILabel!
    @IBOutlet fileprivate weak var dateLabel: UILabel!
    @IBOutlet fileprivate weak var heightView: UIView!
    @IBOutlet fileprivate weak var informationOverlay: UIView!
    
    // location selection
    @IBOutlet fileprivate weak var locationButton: UIBarButtonItem!
    
    // activity indicator
    @IBOutlet fileprivate weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet fileprivate weak var overlayView: UIView!
    
    @IBOutlet fileprivate weak var currentTideHeightConstraint: NSLayoutConstraint!
    
    fileprivate let app: ShralpTideAppDelegate = UIApplication.shared.delegate as! ShralpTideAppDelegate
    fileprivate var tideData: [SingleDayTideModel] = [SingleDayTideModel]()
    fileprivate var displayMonth = Calendar.current.component(.month, from: Date())
    fileprivate var displayYear = Calendar.current.component(.year, from: Date())
    fileprivate var todayIndex: IndexPath?
    fileprivate var displayDayIndex: IndexPath? {
        didSet {
            if displayDayIndex != nil {
                refreshCurrentTide()
                chartView.setNeedsDisplay()
            }
        }
    }
    
    var monthFormat: DateFormatter = DateFormatter() {
        didSet {
            monthFormat.dateFormat = "MMM"
        }
    }
    
    let boldFont: [NSAttributedString.Key: Any] = [
        .font: UIFont.boldSystemFont(ofSize: UIFont.labelFontSize)
    ]
    
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
    
    fileprivate func refreshCurrentTide() {
        let dateString = DateFormatter.localizedString(from: tideDataToChart.startTime, dateStyle: .long, timeStyle: .none)
        dateLabel.text = dateString
        currentDate.text = dateString
        currentLevel.text = String.tideFormatString(value: Float(app.tides[AppStateData.sharedInstance.locationPage].nearestDataPointToCurrentTime.y)) + String.directionIndicator(app.tides[AppStateData.sharedInstance.locationPage].tideDirection)
        eventsTable.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.allowsMultipleSelection = false
        
        navigationItem.title = self.tideDataToChart.shortLocationName
        monthLabel.text = monthYearString()

        refreshTideData(true)
        
        app.supportedOrientations = .allButUpsideDown
        
        currentTideView.heightAnchor.constraint(equalToConstant: view.frame.size.height * 3/4).isActive = true
        
        refreshCurrentTide()
        
        currentTideView.layer.cornerRadius = 5
        currentTideView.layer.masksToBounds = true
        
        heightView.layer.cornerRadius = 5
        heightView.layer.masksToBounds = true
        
        chartView.layer.cornerRadius = 5
        chartView.layer.masksToBounds = true
        chartView.contentMode = .scaleToFill
        
        eventsTable.rowHeight = view.frame.height / 31
        
        populateDaysOfWeek()
        
        resetButton.isHidden = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(refreshTideData), name: .sdApplicationActivated, object: nil)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { context in
            self.currentTideHeightConstraint = self.currentTideHeightConstraint.setMultiplier(multiplier: size.width > size.height ? 0.4 : 0.3)
            self.chartView.setNeedsDisplay()
            self.collectionView.reloadData()
            self.collectionView.selectItem(at: self.displayDayIndex, animated: true, scrollPosition: .centeredVertically)
        }
    }
    
    fileprivate func populateDaysOfWeek() {
        let formatter = DateFormatter()
        let labels = [ day0, day1, day2, day3, day4, day5, day6 ]
        (0..<formatter.weekdaySymbols.count).forEach { i in
            labels[i]?.text = formatter.shortStandaloneWeekdaySymbols[i]
        }
    }
    
    fileprivate func startActivityIndicator() {
        activityIndicator.startAnimating()
        overlayView.frame = collectionView.bounds
        overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.addSubview(overlayView)
    }
    
    fileprivate func stopActivityIndicator() {
        self.activityIndicator.stopAnimating()
        self.overlayView.removeFromSuperview()
    }
    
    @objc func refreshTideData(_ recalculateMonth: Bool = false) {
        navigationItem.title = app.tides[AppStateData.sharedInstance.locationPage].shortLocationName
        refreshCurrentTide()
        chartView.setNeedsDisplay()
        
        if recalculateMonth {
            locationButton.isEnabled = false
            nextButton.isEnabled = false
            prevButton.isEnabled = false
            resetButton.isHidden = true
            startActivityIndicator()
            DispatchQueue.global(qos: .background).async {
                let tides = CalendarTideFactory.createTides(forYear: self.displayYear, month: self.displayMonth)
                self.tideData = tides.map { SingleDayTideModel(tide: $0) }
                DispatchQueue.main.async(execute: self.postRefreshDisplay)
            }
        }
    }
    
    fileprivate func postRefreshDisplay() {
        self.monthLabel.text = self.monthYearString()
        self.displayDayIndex = nil
        updateSelectedDay()
        self.collectionView.reloadData()
        stopActivityIndicator()
        updateDisplayedMonth()
        self.locationButton.isEnabled = true
        self.nextButton.isEnabled = true
        self.prevButton.isEnabled = true
    }
    
    fileprivate func updateDisplayedMonth() {
        if self.displayMonth == Calendar.current.component(.month, from: Date()) &&
            self.displayYear == Calendar.current.component(.year, from: Date()) {
            self.resetButton.isHidden = true
        } else {
            self.resetButton.isHidden = false
        }
    }
    
    fileprivate func updateSelectedDay() {
        if let selectedItems = self.collectionView.indexPathsForSelectedItems {
            selectedItems.forEach { index in
                self.collectionView.deselectItem(at: index, animated: false)
                self.collectionView.cellForItem(at: index)?.isSelected = false
            }
        }
    }
    
    @IBAction func nextMonth() {
        todayIndex = nil
        displayDayIndex = nil
        displayMonth += 1
        refreshTideData(true)
    }
    
    @IBAction func lastMonth() {
        todayIndex = nil
        displayDayIndex = nil
        displayMonth -= 1
        refreshTideData(true)
    }
    
    @IBAction func resetToCurrent() {
        todayIndex = nil
        displayDayIndex = nil
        displayMonth = Calendar.current.component(.month, from: Date())
        displayYear = Calendar.current.component(.year, from: Date())
        refreshTideData(true)
    }
    
    @IBAction func displayFavoritesPopover() {
        let storyboard = UIStoryboard(name: "iPadMain", bundle: nil)
        let locationsVC = storyboard.instantiateViewController(withIdentifier: "locationListController") as! FavoritesListViewController
        locationsVC.modalPresentationStyle = .popover
        locationsVC.popoverPresentationController!.barButtonItem = locationButton
        locationsVC.popoverPresentationController!.delegate = self
        
        present(locationsVC, animated: true, completion: nil)
    }
}

// Collection view data source
extension IPadMainViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tideData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CalendarDayCell", for: indexPath) as! CalendarDayCell
        let dayCellIndex = indexPath.item
        cell.chartView.datasource = tideData[dayCellIndex]
        cell.chartView.hoursToPlot = 24;
        cell.chartView.height = Int(0.8 * (collectionView.layoutAttributesForItem(at: indexPath)!.frame.height - 47))
        cell.chartView.setNeedsDisplay()
        cell.dayLabel.backgroundColor = .black
        
        let today = Date()
        
        let cellMonth = Calendar.current.component(.month, from: tideData[dayCellIndex].day)
        let cellDay = Calendar.current.component(.day, from: tideData[dayCellIndex].day)
        if cellMonth != displayMonth {
            cell.backgroundColor = UIColor.black.withAlphaComponent(1.0)
            cell.dayLabel.textColor = .lightGray
            cell.dayLabel.text = monthFormat.string(from: tideData[dayCellIndex].day) + String(cellDay)
        } else if cellDay == Calendar.current.component(.day, from: today) &&
            cellMonth == Calendar.current.component(.month, from: today){
            cell.layer.cornerRadius = 5
            cell.backgroundColor = UIColor.black.withAlphaComponent(1.0)
            cell.dayLabel.backgroundColor = .yellow
            cell.dayLabel.textColor = .black
            cell.dayLabel.attributedText = NSAttributedString(
                string: " \(String(cellDay)) ",
                attributes: boldFont
            )
            todayIndex = indexPath
            if (displayDayIndex == nil) {
                displayDayIndex = indexPath
                collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredVertically)
                cell.isSelected = true
            }
        } else {
            cell.backgroundColor = UIColor.black.withAlphaComponent(1.0)
            cell.dayLabel.textColor = .white
            cell.dayLabel.text = String(cellDay)
        }
        return cell
    }
}

extension IPadMainViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        displayDayIndex = indexPath
        if let todayIndex = self.todayIndex {
            collectionView.reloadItems(at: [todayIndex])
        }
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        displayDayIndex = nil
        collectionView.reloadItems(at: [indexPath])
    }
}

extension IPadMainViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.superview!.frame.size.width / 7.1
        return CGSize(width: width, height: width)
    }
}

extension IPadMainViewController: ChartViewDatasource {
    var tideDataToChart: SDTide! {
        if let tideIndex = displayDayIndex?.item {
            return tideData[tideIndex].tideDataToChart
        }
        return app.tides[AppStateData.sharedInstance.locationPage]
    }
    
    var day: Date! {
        if let tideIndex = displayDayIndex?.item {
            return tideData[tideIndex].day
        }
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
        self.refreshTideData(true)
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
