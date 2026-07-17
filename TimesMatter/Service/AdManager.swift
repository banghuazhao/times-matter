//
//  AdManager.swift
//  TimesMatter
//
//  Created by Lulin Yang on 2025/7/11.
//

import AdSupport
import AppTrackingTransparency
import GoogleMobileAds
import SwiftUI

enum AdManager {
    static var isAuthorized = false

    enum GoogleAdsID {
        static let bannerViewAdUnitID = Bundle.main.object(forInfoDictionaryKey: "bannerViewAdUnitID") as? String
            ?? "ca-app-pub-3940256099942544/2934735716"
        static let appOpenAdID = Bundle.main.object(forInfoDictionaryKey: "appOpenAdID") as? String
            ?? "ca-app-pub-3940256099942544/5575463023"
    }

    static func requestATTPermission(with time: TimeInterval = 0) {
        guard !isAuthorized else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + time) {
            ATTrackingManager.requestTrackingAuthorization { status in
                switch status {
                case .authorized:
                    isAuthorized = true
                case .denied, .notDetermined, .restricted:
                    break
                @unknown default:
                    break
                }
            }
        }
    }
}

@MainActor
final class OpenAd: NSObject, ObservableObject, FullScreenContentDelegate {
    var appOpenAd: AppOpenAd?
    var loadTime = Date()
    var appHasEnterBackgroundBefore = false
    var bypassAdThisTime = false

    func requestAppOpenAd() {
        let request = Request()
        request.scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        AppOpenAd.load(
            with: AdManager.GoogleAdsID.appOpenAdID,
            request: request
        ) { [weak self] appOpenAdIn, error in
            Task { @MainActor in
                if error != nil {
                    self?.appOpenAd = nil
                    return
                }
                self?.appOpenAd = appOpenAdIn
                self?.appOpenAd?.fullScreenContentDelegate = self
                self?.loadTime = Date()
            }
        }
    }

    func tryToPresentAd() {
        if let gOpenAd = appOpenAd, wasLoadTimeLessThanNHoursAgo(thresholdN: 4) {
            if bypassAdThisTime {
                bypassAdThisTime = false
                return
            }
            guard appHasEnterBackgroundBefore else { return }
            guard let root = Self.topViewController() else { return }
            gOpenAd.present(from: root)
        } else {
            requestAppOpenAd()
        }
    }

    func wasLoadTimeLessThanNHoursAgo(thresholdN: Int) -> Bool {
        let intervalInHours = Date().timeIntervalSince(loadTime) / 3600.0
        return intervalInHours < Double(thresholdN)
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        requestAppOpenAd()
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        requestAppOpenAd()
    }

    private static func topViewController(base: UIViewController? = nil) -> UIViewController? {
        let root: UIViewController?
        if let base {
            root = base
        } else {
            let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            root = scenes
                .flatMap(\.windows)
                .first(where: \.isKeyWindow)?
                .rootViewController
        }
        if let nav = root as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = root as? UITabBarController {
            return topViewController(base: tab.selectedViewController)
        }
        if let presented = root?.presentedViewController {
            return topViewController(base: presented)
        }
        return root
    }
}

/// Reserved-height adaptive banner for SwiftUI, sized with large anchored adaptive APIs (GMA 13+).
struct AdBannerView: View {
    @State private var adHeight: CGFloat = 0
    @State private var didFail = false

    var body: some View {
        Group {
            if didFail {
                Color.clear.frame(height: 0)
            } else {
                AdBannerRepresentable(
                    adHeight: $adHeight,
                    didFail: $didFail
                )
                .frame(height: adHeight > 0 ? adHeight : 100)
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(String(localized: "Advertisement"))
            }
        }
        .animation(.smooth(duration: 0.25), value: adHeight)
        .animation(.smooth(duration: 0.25), value: didFail)
    }
}

private struct AdBannerRepresentable: UIViewControllerRepresentable {
    @Binding var adHeight: CGFloat
    @Binding var didFail: Bool

    func makeUIViewController(context: Context) -> AdBannerViewController {
        let controller = AdBannerViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: AdBannerViewController, context: Context) {
        uiViewController.loadBannerIfNeeded()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, AdBannerViewControllerDelegate {
        var parent: AdBannerRepresentable

        init(_ parent: AdBannerRepresentable) {
            self.parent = parent
        }

        func adBanner(_ controller: AdBannerViewController, didUpdateHeight height: CGFloat) {
            parent.adHeight = height
            parent.didFail = false
        }

        func adBannerDidFailToLoad(_ controller: AdBannerViewController) {
            parent.didFail = true
            parent.adHeight = 0
        }
    }
}

private protocol AdBannerViewControllerDelegate: AnyObject {
    func adBanner(_ controller: AdBannerViewController, didUpdateHeight height: CGFloat)
    func adBannerDidFailToLoad(_ controller: AdBannerViewController)
}

private final class AdBannerViewController: UIViewController, BannerViewDelegate {
    weak var delegate: AdBannerViewControllerDelegate?
    private let bannerView = GoogleMobileAds.BannerView()
    private var lastWidth: CGFloat = 0
    private var hasLoadedForWidth: CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        bannerView.adUnitID = AdManager.GoogleAdsID.bannerViewAdUnitID
        bannerView.rootViewController = self
        bannerView.delegate = self
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        NSLayoutConstraint.activate([
            bannerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bannerView.topAnchor.constraint(equalTo: view.topAnchor),
            bannerView.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor),
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let width = view.bounds.width
        guard width > 0 else { return }
        lastWidth = width
        loadBannerIfNeeded()
    }

    func loadBannerIfNeeded() {
        let width = lastWidth > 0 ? lastWidth : view.bounds.width
        guard width > 0, abs(width - hasLoadedForWidth) > 0.5 else { return }
        hasLoadedForWidth = width
        bannerView.adSize = largeAnchoredAdaptiveBanner(width: width)
        let request = Request()
        request.scene = view.window?.windowScene
            ?? UIApplication.shared.connectedScenes.first as? UIWindowScene
        bannerView.load(request)
    }

    func bannerViewDidReceiveAd(_ bannerView: GoogleMobileAds.BannerView) {
        let height = bannerView.adSize.size.height
        delegate?.adBanner(self, didUpdateHeight: height)
    }

    func bannerView(_ bannerView: GoogleMobileAds.BannerView, didFailToReceiveAdWithError error: Error) {
        delegate?.adBannerDidFailToLoad(self)
    }
}
