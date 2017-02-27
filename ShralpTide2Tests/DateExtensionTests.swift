//
//  ShralpTide2Tests.swift
//  ShralpTide2Tests
//
//  Created by Michael Parlee on 10/4/16.
//
//

import XCTest
import Foundation

class DateExtensionTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testStartOfDay() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let testDate = Date()
        let startOfDay = testDate.startOfDay()
        
        XCTAssertNotEqual(testDate, startOfDay)
        print("Time of day: \(testDate)")
        print("Start of day: \(startOfDay)")
        XCTAssertEqual(startOfDay, Calendar.current.startOfDay(for: testDate))
    }
    
    func testEndOfDay() {
        let testDate = Date()
        let endOfDay = testDate.endOfDay()
        
        XCTAssertNotEqual(testDate, endOfDay)
        print("Time of day: \(testDate)")
        print("End of day: \(endOfDay)")
        XCTAssertEqual(endOfDay, Calendar.current.startOfDay(for: testDate + 86400))
    }
    
    func testIsOnTheHour() {
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        var testDate:Date? = format.date(from: "2016-09-27 15:01:38")
        XCTAssertNotNil(testDate)
        XCTAssertFalse(testDate!.isOnTheHour())
        
        testDate = format.date(from: "2016-09-27 15:00:00")
        XCTAssertTrue(testDate!.isOnTheHour())
        
        testDate = format.date(from: "2016-09-27 15:00:01")
        XCTAssertFalse(testDate!.isOnTheHour())
    }
    
    func testTimeInMinutesFromMidnight() {
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let testDate:Date? = format.date(from: "2016-09-27 15:01:38")
        XCTAssertEqual(testDate!.timeInMinutesSinceMidnight(), 901)
    }
    
    func testFindPreviousInterval() {
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let testDate:Date? = format.date(from: "2016-09-27 15:01:38")
        XCTAssertEqual(testDate!.timeInMinutesSinceMidnight(), 901)
        
        XCTAssertEqual(Date.findPreviousInterval(901), 885)
    }
    
    func testFindNextInterval() {
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let testDate:Date? = format.date(from: "2016-09-27 15:01:38")
        XCTAssertEqual(testDate!.timeInMinutesSinceMidnight(), 901)
        
        XCTAssertEqual(Date.findNearestInterval(901), 900)
        XCTAssertEqual(Date.findNearestInterval(910), 915)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
            _ = Date.findPreviousInterval(906)
        }
    }
    
}
