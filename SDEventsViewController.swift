//
//  SDEventsViewController.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 11/17/18.
//

import Foundation

@objc class SDEventsViewController: UIViewController {

    @IBOutlet fileprivate weak var dateLabel: UILabel! {
        didSet {
            self.dateLabel.adjustsFontSizeToFitWidth = true
            self.dateLabel.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    @IBOutlet fileprivate var chartView: ChartView!
    @IBOutlet fileprivate weak var chartScrollView: UIScrollView!
    @IBOutlet fileprivate weak var bottomVerticalConstraint: NSLayoutConstraint!
    @objc var tide: SDTide!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.removeObserver(self)
        let formatter = DateFormatter()
        formatter.formatterBehavior = DateFormatter.Behavior.default
        formatter.dateStyle = DateFormatter.Style.full
        self.dateLabel.text = formatter.string(from: self.tide.startTime)
        
        chartView.height = 40;
        chartView.datasource = self;
        chartView.hoursToPlot = 24;
        chartView.frame = CGRect(x: 0,
                                  y:0,
                                  width: chartScrollView.frame.size.width,
                                  height: chartView.frame.size.height
        )
        
        chartScrollView.contentSize = chartView.frame.size
        chartScrollView.addSubview(chartView)
    }
}

extension SDEventsViewController: ChartViewDatasource {
    var tideDataToChart: SDTide! {
        return self.tide
    }
    
    var day: Date! {
        return self.tide.startTime
    }
    
    var page: Int32 {
        return 0
    }
}

extension SDEventsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.bounds.size.height / 4
    }
}

extension SDEventsViewController: UITableViewDataSource {
    static let reuseId = "eventCell"
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tide.events(forDay: self.tide.startTime).count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let event = self.tide.events[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: SDEventsViewController.reuseId) as! SDTideEventCell
        cell.timeLabel.text = event.eventTimeNativeFormat
        cell.heightLabel.text = String(format: "%1.2f%@", event.eventHeight, self.tide.unitShort)
        cell.typeLabel.text = event.eventTypeDescription
        return cell
    }
}

