//
//  PouchView.swift
//  PillPouch
//

import SwiftUI
import UIKit

/// 단일 약봉지 컴포넌트. 플라스틱 봉지 + 알약 + 찢기 인터랙션의 조립체.
/// Stage 3: 알약이 motion gravity 따라 봉지 안에서 움직임. Stage 4: middle perforation 따라
/// 좌→우 swipe 로 찢기 (50% 임계 + 햅틱). Stage 5: 낙하.
struct PouchView: View {
    @Binding var state: PouchState
    let slot: TimeSlot
    @Binding var pills: [PillBody]
    /// 화면 좌표계 (x: 우, y: 하) 단위 중력 벡터. ShowcaseView/Today 가 MotionEngine 으로 주입.
    let gravity: SIMD2<Double>
    /// 찢기 시각 스타일 비교용. Showcase 가 토글, Today 는 결정 후 고정.
    var tearStyle: TearStyle = .lift

    @State private var lastTickDate: Date?
    @State private var haptics = PouchHapticDriver()
    @State private var lastTearHapticStep: Int = 0

    var body: some View {
        GeometryReader { geo in
            let bounds = PouchView.pillBounds(in: geo.size)
            TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { context in
                ZStack {
                    ForEach(pills) { pill in
                        PillView(pill: pill)
                    }
                    .opacity(0.96)
                    PouchPaperLayer(slot: slot)
                    PouchTearLayer(state: state, slot: slot, style: tearStyle)
                }
                .contentShape(Rectangle())
                .gesture(tearGesture(width: geo.size.width, perforationY: PouchView.perforationY(in: geo.size)))
                .onChange(of: context.date) { _, newDate in
                    advancePhysics(to: newDate, bounds: bounds)
                }
                .onAppear {
                    haptics.prepare()
                }
            }
        }
    }

    private func advancePhysics(to newDate: Date, bounds: CGRect) {
        let prev = lastTickDate ?? newDate
        let dt = min(newDate.timeIntervalSince(prev), 1.0 / 30.0) // dt 상한 — 백그라운드 복귀 시 점프 방지
        lastTickDate = newDate
        guard dt > 0 else { return }
        let result = PillPhysicsEngine.tick(dt: dt, gravity: gravity, bounds: bounds, pills: &pills)
        if result.shouldPlayHaptic {
            haptics.playImpact(intensity: result.hapticIntensity, at: newDate)
        }
    }

    // MARK: - Tear gesture

    private func tearGesture(width: CGFloat, perforationY: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                handleTearChanged(value, width: width, perforationY: perforationY)
            }
            .onEnded { value in
                handleTearEnded(value, width: width, perforationY: perforationY)
            }
    }

    private func handleTearChanged(_ value: DragGesture.Value, width: CGFloat, perforationY: CGFloat) {
        // 시작점이 perforation Y ±20pt 안 + 이미 .torn 이 아니면 진행.
        guard abs(value.startLocation.y - perforationY) <= Const.startHitTolerance else { return }
        if case .torn = state { return }

        let progress = max(0, min(1, value.translation.width / max(width - Const.tearMargin * 2, 1)))
        let step = Int(progress * 10)
        if step > lastTearHapticStep {
            haptics.playTearStep()
            lastTearHapticStep = step
        }
        state = .tearing(progress: progress)
    }

    private func handleTearEnded(_ value: DragGesture.Value, width: CGFloat, perforationY: CGFloat) {
        guard abs(value.startLocation.y - perforationY) <= Const.startHitTolerance else { return }
        if case .torn = state { return }

        let progress = max(0, min(1, value.translation.width / max(width - Const.tearMargin * 2, 1)))
        if progress >= Const.tearThreshold {
            haptics.playTearSuccess()
            withAnimation(.spring(response: 0.32, dampingFraction: 0.74)) {
                state = .torn
            }
        } else {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                state = .sealed
            }
        }
        lastTearHapticStep = 0
    }

    private enum Const {
        static let startHitTolerance: CGFloat = 20
        static let tearThreshold: Double = 0.5
        static let tearMargin: CGFloat = 16
    }
}

@MainActor
private final class PouchHapticDriver {
    private let impact = UIImpactFeedbackGenerator(style: .light)
    private let tearStepImpact = UIImpactFeedbackGenerator(style: .light)
    private let tearSuccess = UINotificationFeedbackGenerator()
    private var lastImpactDate = Date.distantPast

    func prepare() {
        impact.prepare()
        tearStepImpact.prepare()
        tearSuccess.prepare()
    }

    func playImpact(intensity: Double, at date: Date) {
        guard date.timeIntervalSince(lastImpactDate) >= 0.10 else { return }
        lastImpactDate = date
        impact.impactOccurred(intensity: min(max(intensity, 0.25), 0.65))
        impact.prepare()
    }

    /// Tear 진행도 매 10% 도달 시 호출 — 미세 light × 1.
    func playTearStep() {
        tearStepImpact.impactOccurred(intensity: 0.55)
        tearStepImpact.prepare()
    }

    /// 50% 임계 통과해 torn 확정 시 1번 — 강한 success.
    func playTearSuccess() {
        tearSuccess.notificationOccurred(.success)
        tearSuccess.prepare()
    }
}

extension PouchView {
    /// 봉지 안 알약이 위치 가능한 사각 영역 (perforation 아래 ~ 하단 heat-seal 위).
    /// `PouchPaperLayer.Const`와 짝을 맞춰야 함.
    static func pillBounds(in size: CGSize) -> CGRect {
        let topInset: CGFloat = 14 + 38 + 36 + 8 // topSeal + headerCenter + headerDivider + padding
        let bottomInset: CGFloat = 12 + 6        // bottomSeal + padding
        let sideInset: CGFloat = 12
        return CGRect(
            x: sideInset,
            y: topInset,
            width: size.width - sideInset * 2,
            height: size.height - topInset - bottomInset
        )
    }

    /// Middle perforation 라인의 y 좌표. PouchPaperLayer 의 perforationY 와 동일 식.
    /// Tear gesture 시작점 hit-test 와 PouchTearLayer zigzag 위치가 공유.
    static func perforationY(in size: CGSize) -> CGFloat {
        14 + 38 + 36  // topSeal + headerCenter + headerDivider
    }
}

#Preview("Pouch · Morning · light · 5 pills static") {
    StatePreview()
        .frame(width: 240, height: 320)
        .padding(40)
        .background(PPColor.background)
        .preferredColorScheme(.light)
}

private struct StatePreview: View {
    @State private var pouchState: PouchState = .sealed
    @State private var pills: [PillBody] = {
        let bounds = PouchView.pillBounds(in: CGSize(width: 240, height: 320))
        return PillBody.mock(count: 5, mix: .mixed, bounds: bounds)
    }()
    var body: some View {
        PouchView(state: $pouchState, slot: .morning, pills: $pills, gravity: SIMD2(0, 1))
    }
}
