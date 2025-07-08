//
// Created by Banghua Zhao on 08/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//
  

import SwiftUI

@Observable
@MainActor
class MeModel {
    
}

struct MeView: View {
    @State var model = MeModel()
    
    var body: some View {
        Text("Me")
    }
}
