//
// Created by Banghua Zhao on 08/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import Dependencies

// MARK: - App Timer Implementation
@Observable
class AppTimer {
    @MainActor
    var currentTime: Date = Date()
    private var timer: Timer?
    
    static let shared = AppTimer()
    
    private init() {
        startTimer()
    }
    
    func startTimer() {
        // Stop existing timer if running
        stopTimer()
        
        // Start new timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.currentTime = Date()
            }
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - DependencyKey for TimerService
private enum TimerServiceKey: DependencyKey {
    static let liveValue: AppTimer = AppTimer.shared
}

extension DependencyValues {
    var timerService: AppTimer {
        get { self[TimerServiceKey.self] }
        set { self[TimerServiceKey.self] = newValue }
    }
} 
