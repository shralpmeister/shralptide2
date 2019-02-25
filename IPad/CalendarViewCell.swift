//
//  CalendarViewCell.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 12/21/18.
//

import Foundation

class CalendarViewCell: UICollectionViewCell, UICollectionViewDataSource {
    
    var tides: [ChartViewDatasource] = [ChartViewDatasource]()
    var displayedMonth = Calendar.current.component(.month, from: Date())
    var displayYear = Calendar.current.component(.year, from: Date())
    let monthFormat = DateFormatter()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        monthFormat.dateFormat = "MMM"
    }
    
    @IBOutlet var collectionView: UICollectionView!
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tides.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CalendarDayCell", for: indexPath) as! CalendarDayCell
        let dayCellIndex = indexPath.item
        cell.chartView.datasource = tides[dayCellIndex]
        cell.chartView.hoursToPlot = 24;
        cell.chartView.height = Int(0.8 * (collectionView.layoutAttributesForItem(at: indexPath)!.frame.height - 47))
        cell.chartView.setNeedsDisplay()
        
        let cellMonth = Calendar.current.component(.month, from: tides[dayCellIndex].day)
        let cellDay = Calendar.current.component(.day, from: tides[dayCellIndex].day)
        if cellMonth != displayedMonth {
            cell.backgroundColor = UIColor.black.withAlphaComponent(1.0)
            cell.dayLabel.textColor = UIColor.lightGray
            cell.dayLabel.text = monthFormat.string(from: tides[dayCellIndex].day) + String(cellDay)
        } else if cellDay == Calendar.current.component(.day, from: Date()) {
            cell.backgroundColor = UIColor.black.withAlphaComponent(1.0)
            cell.dayLabel.textColor = UIColor.yellow
            cell.dayLabel.text = String(cellDay)
        } else {
            cell.backgroundColor = UIColor.black.withAlphaComponent(1.0)
            cell.dayLabel.textColor = UIColor.white
            cell.dayLabel.text = String(cellDay)
        }
        return cell
    }
}

extension CalendarViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.superview!.frame.size.width / 7.1
        return CGSize(width: width, height: width)
    }
}
