//
// Created by Banghua Zhao on 08/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//
  

import SwiftUI

@Observable
@MainActor
class CountdownFormModel {
    
}

struct CountdownFormView: View {
    @State var model = CountdownFormModel()
    
    var body: some View {
        Text("CountDown Form")
    }
}
