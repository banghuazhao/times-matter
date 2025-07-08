//
// Created by Banghua Zhao on 08/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//
  

import SwiftUI
import SharingGRDB

@Observable
@MainActor
class CountdownListModel {
    @ObservationIgnored
    @FetchAll(Countdown.all) var countdowns
}

struct CountdownListView: View {
    @State var model = CountdownListModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(model.countdowns) { countdown in
                    CountdownRow(countdown: countdown)
                }
            }
            .padding(16)
        }
        .toolbar {
            
        }
    }
}
