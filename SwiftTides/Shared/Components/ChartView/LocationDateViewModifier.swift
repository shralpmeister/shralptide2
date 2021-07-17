//
//  LocationDateViewModifier.swift
//  SwiftTides
//
//  Created by Michael Parlee on 4/9/21.
//

import SwiftUI

struct LocationDateViewModifier: ViewModifier {
    private var location: String?
    private var date: Date

    private var dateFormatter = DateFormatter()

    init(location: String? = nil, date: Date) {
        self.location = location
        self.date = date
        dateFormatter.dateStyle = .full
    }

    func body(content: Content) -> some View {
        return GeometryReader { proxy in
            content.overlay(
                HStack(alignment: .bottom) {
                    if location != nil {
                        Text(location!)
                    }
                    Spacer()
                    Text(dateFormatter.string(from: date))
                }
                .font(.body)
                .minimumScaleFactor(0.2)
                .padding(.leading)
                .padding(.trailing)
                .foregroundColor(.white)
                .frame(maxHeight: 30)
                .position(x: proxy.size.width / 2.0, y: 50)
            )
        }
    }
}
