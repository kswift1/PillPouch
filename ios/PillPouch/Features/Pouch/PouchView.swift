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

    @State private var lastTickDate: Date?
    @State private var haptics = PouchHapticDriver()
    @State private var lastTearHapticStep: Int = 0
    /// 새 drag 시작 시점의 progress base. drag end 또는 외부 state 변경 시 갱신.
    @State private var dragBaseProgress: Double = 0
    /// torn 진입 시 true — physics 정지 + 알약 list slot 으로 spring stagger.
    @State private var listMode: Bool = false
    /// torn 시 mock 위치 백업 (봉합 시 복귀용).
    @State private var pillsBeforeTear: [PillBody] = []

    var body: some View {
        GeometryReader { geo in
            let bounds = PouchView.pillBounds(in: geo.size)
            TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { context in
                ZStack {
                    ForEach(pills) { pill in
                        PillView(pill: pill)
                    }
                    .opacity(0.96)
                    if listMode {
                        ForEach(pills) { pill in
                            HStack(spacing: 0) {
                                Text("\(PillCategoryDisplayName.label(for: pill.categoryKey)) · \(pill.dose)정")
                                    .font(PPFont.body)
                                    .foregroundStyle(PPColor.textPrimary)
                                Spacer(minLength: 4)
                                if let takenAt = pill.takenAt {
                                    Text(takenAt, format: .dateTime.hour().minute())
                                        .font(.system(.callout, design: .monospaced))
                                        .foregroundStyle(PPColor.textSecondary)
                                }
                            }
                            .frame(width: Const.labelWidth)
                            .position(
                                x: pill.position.x + Const.labelStartOffset + Const.labelWidth / 2,
                                y: pill.position.y
                            )
                            .transition(.opacity.combined(with: .offset(x: -8, y: 0)))
                            .allowsHitTesting(false)
                        }
                    }
                    paperLayerStack
                        .opacity(listMode ? 0 : 1)
                        .offset(y: listMode ? -Const.paperLiftAway : 0)
                        .animation(.easeOut(duration: 0.45), value: listMode)
                }
                .contentShape(Rectangle())
                .gesture(tearGesture(width: geo.size.width, perforationY: PouchView.perforationY(in: geo.size)))
                .onChange(of: context.date) { _, newDate in
                    advancePhysics(to: newDate, bounds: bounds)
                }
                .onChange(of: state) { _, newState in
                    syncDragBase(to: newState)
                    syncListMode(to: newState, bounds: bounds)
                }
                .onAppear {
                    haptics.prepare()
                    syncDragBase(to: state)
                    syncListMode(to: state, bounds: bounds)
                }
            }
        }
    }

    /// PaperLayer 합성 — 위/아래 두 조각 분리, 위쪽이 progress 따라 transform.
    /// PaperTop/Bottom 은 같은 seed JaggedTearPath mask 로 단면 정확히 맞물림.
    @ViewBuilder
    private var paperLayerStack: some View {
        PouchPaperBottom(slot: slot, tearProgress: tearProgress)
        PouchPaperTop(slot: slot, tearProgress: tearProgress)
            .offset(y: -tearLiftDistance)
            .rotationEffect(.degrees(tearTiltAngle), anchor: .top)
            .shadow(color: .black.opacity(tearShadowOpacity), radius: 4, x: 0, y: 2)
    }

    private var tearProgress: Double {
        switch state {
        case .sealed: return 0
        case .tearing(let p): return p
        case .torn: return 1
        }
    }

    private var tearLiftDistance: CGFloat { CGFloat(tearProgress) * 8 }
    private var tearTiltAngle: Double { tearProgress * 6 }
    private var tearShadowOpacity: Double { tearProgress * 0.20 }

    private func advancePhysics(to newDate: Date, bounds: CGRect) {
        let prev = lastTickDate ?? newDate
        let dt = min(newDate.timeIntervalSince(prev), 1.0 / 30.0) // dt 상한 — 백그라운드 복귀 시 점프 방지
        lastTickDate = newDate
        guard dt > 0 else { return }
        guard !listMode else { return }  // torn list mode 에선 physics 정지
        let result = PillPhysicsEngine.tick(dt: dt, gravity: gravity, bounds: bounds, pills: &pills)
        if result.shouldPlayHaptic {
            haptics.playImpact(intensity: result.hapticIntensity, at: newDate)
        }
    }

    // MARK: - List mode (torn 후 알약 + 라벨 리스트)

    private func syncListMode(to newState: PouchState, bounds: CGRect) {
        switch newState {
        case .torn:
            if !listMode {
                startListLayout(bounds: bounds)
            }
        case .sealed:
            if listMode {
                restorePhysicsLayout(bounds: bounds)
            }
        case .tearing:
            break
        }
    }

    private func startListLayout(bounds: CGRect) {
        // 봉합 시 복원 위해 mock 위치 백업
        pillsBeforeTear = pills
        listMode = true
        // 한 봉지 = 한 슬롯 동시 복용 — 모든 알약 같은 takenAt.
        let takenAt = Date()
        for i in pills.indices {
            let target = listSlotPosition(index: i, count: pills.count, bounds: bounds)
            let delay = Double(i) * Const.listStaggerDelay
            pills[i].takenAt = takenAt
            withAnimation(.spring(response: 0.55, dampingFraction: 0.72).delay(delay)) {
                pills[i].position = target
                pills[i].rotation = 0
                pills[i].velocity = .zero
                pills[i].angularVelocity = 0
            }
        }
    }

    private func restorePhysicsLayout(bounds: CGRect) {
        listMode = false
        guard !pillsBeforeTear.isEmpty else { return }
        let restored = pillsBeforeTear
        for i in pills.indices where i < restored.count {
            pills[i].takenAt = nil
            withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                pills[i].position = restored[i].position
                pills[i].rotation = restored[i].rotation
                pills[i].velocity = .zero
                pills[i].angularVelocity = 0
            }
        }
    }

    /// list slot 위치 — 봉지 안 좌측 정렬, 세로 균등 배치.
    private func listSlotPosition(index: Int, count: Int, bounds: CGRect) -> CGPoint {
        let usableHeight = bounds.height
        let rowSpacing = max(usableHeight / CGFloat(max(count, 1) + 1), Const.listMinRowSpacing)
        let x = bounds.minX + Const.listLeftMargin
        let y = bounds.minY + rowSpacing * CGFloat(index + 1)
        return CGPoint(x: x, y: y)
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

        let usableWidth = max(width - Const.tearMargin * 2, 1)
        let dragDelta = Double(value.translation.width) / Double(usableWidth)
        let progress = max(0, min(1, dragBaseProgress + dragDelta))

        let step = Int(progress * 10)
        if step > lastTearHapticStep {
            haptics.playTearStep()
            lastTearHapticStep = step
        }

        if progress >= 1.0 {
            haptics.playTearSuccess()
            withAnimation(.spring(response: 0.32, dampingFraction: 0.74)) {
                state = .torn
            }
        } else {
            state = .tearing(progress: progress)
        }
    }

    private func handleTearEnded(_ value: DragGesture.Value, width: CGFloat, perforationY: CGFloat) {
        guard abs(value.startLocation.y - perforationY) <= Const.startHitTolerance else { return }
        // 진행도 유지 — auto snap (sealed/torn) 없음. 다음 drag 의 base 갱신만.
        switch state {
        case .sealed:
            dragBaseProgress = 0
        case .tearing(let p):
            dragBaseProgress = p
        case .torn:
            dragBaseProgress = 1.0
        }
    }

    /// 외부에서 state 가 바뀌면 (Showcase 봉합/찢기 버튼) drag base 와 햅틱 step 동기화.
    /// drag 중에는 .tearing 갱신이 자기 자신 발생이므로 무시.
    private func syncDragBase(to newState: PouchState) {
        switch newState {
        case .sealed:
            dragBaseProgress = 0
            lastTearHapticStep = 0
        case .torn:
            dragBaseProgress = 1.0
            lastTearHapticStep = 10
        case .tearing:
            break
        }
    }

    private enum Const {
        static let startHitTolerance: CGFloat = 20
        static let tearMargin: CGFloat = 16
        static let listStaggerDelay: Double = 0.08
        static let listMinRowSpacing: CGFloat = 36
        static let listLeftMargin: CGFloat = 30
        static let labelStartOffset: CGFloat = 30
        static let labelWidth: CGFloat = 180
        static let paperLiftAway: CGFloat = 30
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
