//
// Created by Banghua Zhao on 08/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//
  

import SwiftUI
import Dependencies

@Observable
@MainActor
class CountdownDetailModel {
    let countdown: Countdown
    @ObservationIgnored
    @Dependency(\.timerService) var timerService
    
    init(countdown: Countdown) {
        self.countdown = countdown
    }
}

struct CountdownDetailView: View {
    @State var model: CountdownDetailModel
    
    var body: some View {
        Text("CountDown Detail")
    }
}
