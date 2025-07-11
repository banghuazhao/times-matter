//
// Created by Banghua Zhao on 11/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct NavigationBarColor: ViewModifier {
    var tintColor: UIColor

    func body(content: Content) -> some View {
        content
            .background(NavBarConfigurator(tintColor: tintColor))
    }

    struct NavBarConfigurator: UIViewControllerRepresentable {
        var tintColor: UIColor

        func makeUIViewController(context: Context) -> UIViewController {
            let controller = UIViewController()
            DispatchQueue.main.async {
                controller.navigationController?.navigationBar.tintColor = tintColor
            }
            return controller
        }

        func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
            DispatchQueue.main.async {
                uiViewController.navigationController?.navigationBar.tintColor = tintColor
            }
        }
    }
}

extension View {
    func navigationBarTint(_ color: UIColor) -> some View {
        modifier(NavigationBarColor(tintColor: color))
    }
}
