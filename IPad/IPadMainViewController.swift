//
//  IPadMainViewController.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 11/22/18.
//

import Foundation

class IPadMainViewController: UIViewController {
    
    @IBOutlet fileprivate weak var collectionView: UICollectionView!
    @IBOutlet fileprivate weak var chartView: InteractiveChartView!
    @IBOutlet fileprivate weak var heightLabel: UILabel!
    @IBOutlet fileprivate weak var locationLabel: UILabel!
    @IBOutlet fileprivate weak var dateLabel: UILabel!
    @IBOutlet fileprivate weak var heightView: UIView!
    @IBOutlet fileprivate weak var informationOverlay: UIView!
    
    fileprivate let app: ShralpTideAppDelegate = UIApplication.shared.delegate as! ShralpTideAppDelegate
    fileprivate var tideData: [SingleDayTideModel] = [SingleDayTideModel]()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(refreshTideData), name: .sdApplicationActivated, object: nil)

        let tides = CalendarTideFactory.tidesForCurrentMonth()
        self.tideData = tides.map { SingleDayTideModel(tide: $0) }
        
        app.supportedOrientations = .allButUpsideDown
        
        self.locationLabel.text = self.tideDataToChart.shortLocationName
        self.dateLabel.text = DateFormatter.localizedString(from: self.tideDataToChart.startTime, dateStyle: .long, timeStyle: .none)
        
        self.heightView.layer.cornerRadius = 5
        self.heightView.layer.masksToBounds = true
    }
    
    @objc func refreshTideData() {
        let tide: SDTide = app.tides[AppStateData.sharedInstance.locationPage]
        let currentTideCell = self.collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as! CurrentTideCell
        currentTideCell.refresh(tide: tide)
    }
}

// Collection view data source
extension IPadMainViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "LocationHeaderView", for: indexPath) as! LocationHeaderView
        headerView.refresh(tide: app.tides[0])
        return headerView
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.item {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CurrentTideView", for: indexPath) as! CurrentTideCell
            cell.refresh(tide: app.tides[0])
            return cell
        case 1:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChartViewCell", for: indexPath) as! ChartViewCell
            if let layout = collectionView.layoutAttributesForItem(at: indexPath) {
                chartView.height = Int(layout.bounds.size.height * 3/4)
            }
            cell.contentView.addSubview(chartView)
            chartView.addSubview(informationOverlay)
            return cell
        default:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CalendarViewCell", for: indexPath) as! CalendarViewCell
            cell.tides = self.tideData
            return cell
        }
    }
}

extension IPadMainViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch indexPath.item {
        case 0:
            return CGSize(width: 255, height: 275)
        case 1:
            return CGSize(width: 524, height: 275)
        default:
            return CGSize(width: 794, height: collectionView.frame.size.height - 275 - 70)
        }
    }
}

extension IPadMainViewController: ChartViewDatasource {
    var tideDataToChart: SDTide! {
        return app.tides[0]
    }
    
    var day: Date! {
        return Date().startOfDay()
    }
    
    var page: Int32 {
        return 0
    }
}

extension IPadMainViewController: InteractiveChartViewDelegate {
    func interactionsEnded() {
        UIView.beginAnimations("displayHeightAnimation", context: nil)
        self.heightView.alpha = 0.0;
        UIView.commitAnimations()
    }
    
    func displayHeight(_ height: CGFloat, atTime time: Date!, withUnitString units: String!) {
        UIView.beginAnimations("displayHeightAnimation", context: nil)
        self.heightView.alpha = 1.0
        self.heightLabel.text = String(format: "%0.2f %@ @ %@", height, units, DateFormatter.localizedString(from: time, dateStyle: .none, timeStyle: .short))
        UIView.commitAnimations()
    }
}
