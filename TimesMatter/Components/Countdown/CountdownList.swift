//
// Created by Banghua Zhao on 08/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//
  

import SwiftUI

@Observable
@MainActor
class CountdownListModel {
    
}

struct CountdownListView: View {
    @State var model = CountdownListModel()
    
    var body: some View {
        Text("all countdowns")
    }
}
