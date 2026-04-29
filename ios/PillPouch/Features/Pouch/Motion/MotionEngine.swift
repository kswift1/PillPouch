//
//  MotionEngine.swift
//  PillPouch
//

import CoreMotion
import Foundation
import Observation

/// 디바이스 중력 벡터를 SwiftUI 좌표계로 매핑해 publish 하는 인터페이스.
/// 실 기기는 `RealMotionEngine` (CMMotionManager 래핑), 시뮬레이터는 `MotionEngineMock`.
@MainActor
protocol MotionEngineProtocol: AnyObject {
    /// 화면 좌표계 (x: 우, y: 하) 정규화 중력 벡터. `(0, 1)` = 정상 세로 들고 있음.
    var gravity: SIMD2<Double> { get }
    func start()
    func stop()
}

/// 실 기기 CMMotionManager 래핑. CMMotionManager.deviceMotion 의 gravity 를 60Hz 로 publish.
@MainActor
@Observable
final class RealMotionEngine: MotionEngineProtocol {
    private(set) var gravity: SIMD2<Double> = SIMD2(0, 1)
    private let manager = CMMotionManager()

    func start() {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 60.0
        // .main OperationQueue → closure 는 메인 스레드 fire. Swift 6 strict 에서 @Sendable
        // closure 안에서 self 직접 캡처 불가 → MainActor.assumeIsolated 로 단언.
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let motion else { return }
            MainActor.assumeIsolated {
                // CMMotionManager: x 우, y 위, z 화면 밖. SwiftUI: x 우, y 아래. y 부호 반전.
                self?.gravity = SIMD2(motion.gravity.x, -motion.gravity.y)
            }
        }
    }

    func stop() {
        if manager.isDeviceMotionActive {
            manager.stopDeviceMotionUpdates()
        }
    }
}

/// 시뮬레이터 / 데모용. 두 모드:
/// - `.auto`: 천천히 회전하는 가짜 gravity (8초 주기)
/// - `.manual(SIMD2)`: ShowcaseView 슬라이더가 직접 set
@MainActor
@Observable
final class MotionEngineMock: MotionEngineProtocol {
    enum Mode {
        case auto
        case manual
    }

    var mode: Mode = .auto
    /// `.manual` 모드에서 외부 (ShowcaseView Slider) 가 직접 set.
    var manualGravity: SIMD2<Double> = SIMD2(0, 1)
    private(set) var gravity: SIMD2<Double> = SIMD2(0, 1)

    private var motionTask: Task<Void, Never>?
    private var startedAt: Date?

    func start() {
        startedAt = Date()
        motionTask?.cancel()
        // Timer 대신 Task — Swift 6 strict concurrency 친화. cancel 로 stop 명확.
        motionTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(1_000_000_000.0 / 30.0))
                guard !Task.isCancelled else { return }
                self?.advance()
            }
        }
    }

    func stop() {
        motionTask?.cancel()
        motionTask = nil
    }

    private func advance() {
        switch mode {
        case .auto:
            let elapsed = Date().timeIntervalSince(startedAt ?? Date())
            let angle = elapsed * (2 * .pi / 4.0) // 4초 주기 — 활발한 데모
            gravity = SIMD2(sin(angle), cos(angle) * 0.6 + 0.4)
        case .manual:
            gravity = manualGravity
        }
    }
}

/// 환경별 적정 엔진 factory. 시뮬레이터에서는 자동으로 mock.
@MainActor
enum MotionEngineFactory {
    static func make() -> MotionEngineProtocol {
        #if targetEnvironment(simulator)
        return MotionEngineMock()
        #else
        return RealMotionEngine()
        #endif
    }
}
