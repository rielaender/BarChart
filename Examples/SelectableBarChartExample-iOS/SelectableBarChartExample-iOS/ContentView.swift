//
//  ContentView.swift
//  SelectableBarChartExample-iOS
//
//  Copyright (c) 2020 Roman Baitaliuk
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.

import SwiftUI
import BarChart

struct ContentView: View {
    
    let orientationChanged = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
        .makeConnectable()
        .autoconnect()
    
    // MARK: - Chart Properties
    
    let chartHeight: CGFloat = 300
    let config = ChartConfiguration()
    let animationDuration = 0.1
    let ticksColor = Color(UIColor.systemGray5)
    let labelsColor = Color.gray

    
    // MARK: - Selection Indicator
    
    let selectionIndicatorHeight: CGFloat = 60
    @State var selectedBarTopCentreLocation: CGPoint?
    @State var selectedEntry: ChartDataEntry?
    @State var showSelectionIndicator: Bool = false
    
    init() {
        self.config.xAxis.labelsColor = labelsColor
        self.config.xAxis.ticksColor = ticksColor
        self.config.xAxis.ticksStyle = StrokeStyle(lineWidth: 1, lineCap: .round, dash: [2, 4])
        self.config.xAxis.ticksInterval = 6
        self.config.xAxis.startTicksIntervalFromBeginning = true
        
        self.config.yAxis.labelsColor = labelsColor
        self.config.yAxis.ticksColor = ticksColor
        self.config.yAxis.ticksStyle = StrokeStyle(lineWidth: 1, lineCap: .round)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 10) {
                    ZStack {
                        VStack(alignment: .leading) {
                            HStack {
                                if !self.showSelectionIndicator {
                                    Text("Verlangen nach Uhrzeit")
                                }
                                Spacer()
                            }
                            Spacer()
                        }
                        .background(Color(UIColor.systemBackground))
                        .onTapGesture {
                            self.resetSelection()
                        }
                        self.selectableChartView()
                    }.padding()
                    Button(action: {
                        self.resetSelection()
                        self.config.data.entries = self.randomEntries()
                    }, label: {
                        Text("Random entries")
                    })
                    .onReceive(self.orientationChanged) { _ in
                        self.config.objectWillChange.send()
                        self.resetSelection()
                    }
                    .onAppear() {
                        // SwiftUI bug, onAppear is called before the view frame is calculated
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                            self.config.data.entries = self.randomEntries()
                            self.config.objectWillChange.send()
                        })
                    }
                    .navigationBarTitle(Text("Meine Einträge"))
                }
            }
        }.navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Views
    
    func selectableChartView() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            self.selectionIndicatorView()
                .onTapGesture {
                    self.resetSelection()
                }
            self.chartView()
                .background(Color(UIColor.systemBackground))
        }
        .frame(height: chartHeight)
    }
    
    func chartView() -> some View {
        GeometryReader { proxy in
            SelectableBarChartView<SelectionLine>(config: self.config)
                .onBarSelection { entry, location in
                    self.setSelection(location: location, entry: entry)
                }
                .selectionView {
                    SelectionLine(location: self.selectedBarTopCentreLocation,
                                  height: proxy.size.height - 17,
                                  color: Color(UIColor.systemGray4))
                }
        }
    }
    
    func selectionIndicatorView() -> some View {
        Group {
            if self.showSelectionIndicator && self.selectedEntry != nil && self.selectedBarTopCentreLocation != nil {
                let x = Int(self.selectedEntry!.x)
                let label = x == nil ? self.selectedEntry!.x : "\(x!)-\((x! + 1) % 24) Uhr"
                let entry = ChartDataEntry(x: label, y: self.selectedEntry!.y)
                SelectionIndicator(entry: entry,
                                   location: self.selectedBarTopCentreLocation!.x,
                                   infoRectangleColor: Color(UIColor.systemGray6),
                                   unitLabel: "Verlangen")
            } else {
                Rectangle().foregroundColor(.clear)
            }
        }
        .frame(height: self.selectionIndicatorHeight)
    }
    
    func randomEntries() -> [ChartDataEntry] {
        var entries = [ChartDataEntry]()
        for data in 0..<24 {
            let randomDouble = max(Double.random(in: -10...20), 0).rounded()
            let newEntry = ChartDataEntry(x: "\(String(format: "%02d", data))", y: randomDouble)
            entries.append(newEntry)
        }
        return entries
    }
    
    func setSelection(location: CGPoint, entry: ChartDataEntry) {
        withAnimation(.easeIn(duration: self.animationDuration)) {
            self.showSelectionIndicator = true
            self.selectedBarTopCentreLocation = location
            self.selectedEntry = entry
        }
    }
    
    func resetSelection() {
        withAnimation(.easeIn(duration: self.animationDuration)) {
            self.showSelectionIndicator = false
            self.selectedBarTopCentreLocation = nil
            self.selectedEntry = nil
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
            ContentView().preferredColorScheme(.dark)
        }
    }
}
