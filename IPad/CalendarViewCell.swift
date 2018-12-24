//
//  CalendarViewCell.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 12/21/18.
//

import Foundation

class CalendarViewCell: UICollectionViewCell, UICollectionViewDataSource {
    
    var tides: [ChartViewDatasource] = [ChartViewDatasource]()
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tides.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CalendarDayCell", for: indexPath) as! CalendarDayCell
        let dayCellIndex = indexPath.item
        cell.chartView.datasource = tides[dayCellIndex]
        cell.chartView.hoursToPlot = 24;
        cell.chartView.height = 40
        cell.chartView.setNeedsDisplay()

        //let format = DateFormatter()
        //format.dateStyle = .short
        //format.timeStyle = .none
        //cell.dayLabel.text = format.string(from: tides[dayCellIndex].day)
        cell.dayLabel.text = String(Calendar.current.component(.day, from: tides[dayCellIndex].day))
        return cell
    }
}
