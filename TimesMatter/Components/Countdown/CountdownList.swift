//
// Created by Banghua Zhao on 08/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//
  

import SwiftUI
import SharingGRDB
import SwiftUINavigation

@Observable
@MainActor
class CountdownListModel {
    @ObservationIgnored
    @FetchAll(Countdown.all) var countdowns
    
    @CasePathable
    enum Route {
        case countdownForm(CountdownFormModel)
        case countdownDetail(CountdownDetailModel)
    }
    var route: Route?
    
    func onTapCountDown(_ countdown: Countdown) {
        route = .countdownDetail(
            CountdownDetailModel(countdown: countdown)
        )
    }
    
    func onTapAddCountDown() {
        route = .countdownForm(
            CountdownFormModel(
                countdown: Countdown.Draft()
            )
        )
    }
}

struct CountdownListView: View {
    @State var model = CountdownListModel()
    @State private var showingNewCountdown = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(model.countdowns) { countdown in
                    CountdownRow(countdown: countdown)
                        .onTapGesture {
                            model.onTapCountDown(countdown)
                        }
                }
            }
            .padding(16)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: model.onTapAddCountDown) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.appCircular)
            }
        }
        .sheet(item: $model.route.countdownForm, id: \.self) { model in
            CountdownFormView(model: model)
        }
        .navigationDestination(item: $model.route.countdownDetail) { model in
            CountdownDetailView(model: model)
        }
    }
}
