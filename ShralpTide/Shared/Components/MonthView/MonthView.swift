//
//  MonthView.swift
//  SwiftTides
//
//  Created by Michael Parlee on 3/31/21.
//

import Combine
import ShralpTideFramework
import SwiftUI

struct MonthView: View {
    @Environment(\.appStateInteractor) private var appStateInteractor: AppStateInteractor

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var config: ConfigHelper

    @Binding var selectedTideModel: SingleDayTideModel?

    @State private var displayMonth = Calendar.current.component(.month, from: Date()) {
        didSet {
            backgroundRefreshTides()
        }
    }

    @State private var displayYear = Calendar.current.component(.year, from: Date())
    @State private var calculating = false

    fileprivate let monthDateFormatter = DateFormatter()

    private let gridColumns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    displayMonth -= 1
                }) {
                    Image(systemName: "backward")
                }
                .disabled(calculating)
                Spacer()
                Text(monthYearString())
                    .font(.title)
                if displayMonth != Calendar.current.component(.month, from: Date())
                    || displayYear != Calendar.current.component(.year, from: Date())
                {
                    Button(action: {
                        displayMonth = Calendar.current.component(.month, from: Date())
                        displayYear = Calendar.current.component(.year, from: Date())
                    }) {
                        Image(systemName: "arrow.uturn.backward")
                    }
                }
                Spacer()
                Button(action: {
                    displayMonth += 1
                }) {
                    Image(systemName: "forward")
                }
                .padding()
                .disabled(calculating)
            }
        }
        VStack {
            HStack(alignment: .center, spacing: 0) {
                Text("Sun")
                    .frame(maxWidth: .infinity)
                Text("Mon")
                    .frame(maxWidth: .infinity)
                Text("Tue")
                    .frame(maxWidth: .infinity)
                Text("Wed")
                    .frame(maxWidth: .infinity)
                Text("Thr")
                    .frame(maxWidth: .infinity)
                Text("Fri")
                    .frame(maxWidth: .infinity)
                Text("Sat")
                    .frame(maxWidth: .infinity)
            }
            ZStack {
                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: 1) {
                        ForEach(appState.calendarTides, id: \.self) { tide in
                            CalendarDayView(model: tide)
                                .onTapGesture {
                                    selectedTideModel = tide
                                }
                                .border(Color.yellow, width: selectedTideModel == tide ? 3 : 0)
                                .clipShape(RoundedRectangle(cornerRadius: 3.0))
                        }
                    }
                }
                if calculating {
                    Rectangle()
                        .fill(Color.black.opacity(0.75))
                        .frame(width: nil, height: nil)
                        .ignoresSafeArea()
                    ProgressView()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification))
        { _ in
            // state update to force redraw the scrollview
            appState.locationPage = appState.locationPage
        }
        .onAppear {
            appState.calendarTides = appStateInteractor.calculateCalendarTides(
                appState: appState, settings: config.settings, month: displayMonth, year: displayYear
            )
            if selectedTideModel == nil {
                selectedTideModel = appState.calendarTides.first {
                    $0.day == Date().startOfDay()
                }
            }
            _ = appState.$locationPage.subscribe(on: DispatchQueue.main).sink { page in
                if appState.locationPage != page {
                    calculating = true
                    _ = refreshTidesFuture()
                        .subscribe(on: DispatchQueue.main)
                        .receive(on: DispatchQueue.main)
                        .sink { tides in
                            appState.calendarTides = tides
                            calculating = false
                            selectedTideModel = appState.calendarTides.first {
                                $0.day == Date().startOfDay()
                            }
                        }
                }
            }
        }
    }

    fileprivate func refreshTidesFuture() -> Future<[SingleDayTideModel], Never> {
        Future<[SingleDayTideModel], Never> { promise in
            DispatchQueue.global(qos: .userInteractive).async {
                let tides = appStateInteractor.calculateCalendarTides(
                    appState: appState, settings: appState.config.settings, month: displayMonth,
                    year: displayYear
                )
                promise(Result.success(tides))
            }
        }
    }

    fileprivate func backgroundRefreshTides() {
        calculating = true
        _ = refreshTidesFuture()
            .subscribe(on: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .sink { tides in
                appState.calendarTides = tides
                calculating = false
                // if we're showing the current and the selected tide is in a different month, reset it back to today
                if displayMonth == Calendar.current.component(.month, from: Date()),
                   displayMonth != Calendar.current.component(.month, from: selectedTideModel!.day)
                {
                    selectedTideModel = tides.first {
                        $0.day == Date().startOfDay()
                    }
                }
            }
    }

    fileprivate func monthYearString() -> String {
        let date = Calendar.current.date(from: DateComponents(year: displayYear, month: displayMonth))!
        monthDateFormatter.setLocalizedDateFormatFromTemplate("MMMM YYYY")
        return monthDateFormatter.string(from: date)
    }
}
