//
// Navigation chrome helpers — pure SwiftUI (no UIKit representable bridge).
//

import SwiftUI

extension View {
    /// Sets navigation bar item tint without UIKit appearance proxies.
    func navigationBarTint(_ color: Color) -> some View {
        tint(color)
    }

    /// Dark/light scheme for bars over photo or branded chrome.
    func appNavigationChrome(scheme: ColorScheme? = nil) -> some View {
        Group {
            if let scheme {
                self.toolbarColorScheme(scheme, for: .navigationBar)
            } else {
                self
            }
        }
    }
}
