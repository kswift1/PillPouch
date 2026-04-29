//
//  PouchShowcaseView.swift
//  PillPouch
//

import SwiftUI

/// 단일 봉지 컴포넌트 데모/디버그 화면. 개발 진입점.
/// Stage 3: motion 모드 토글 (실 기기/시뮬 mock auto/manual) + manual gravity 슬라이더.
struct PouchShowcaseView: View {
    @State private var slot: TimeSlot = .morning
    @State private var pillCount: Double = 5
    @State private var mix: PillMix = .mixed
    @State private var resetToken: Int = 0
    @State private var pills: [PillBody] = []

    @State private var motionMode: MotionEngineMock.Mode = .auto
    @State private var manualGravityX: Double = 0
    @State private var manualGravityY: Double = 1
    @State private var motionEngine: MotionEngineProtocol = MotionEngineFactory.make()

    private let pouchSize = CGSize(width: 260, height: 340)

    var body: some View {
        ZStack {
            PPColor.background.ignoresSafeArea()
            VStack(spacing: PPSpacing.md) {
                Spacer()
                PouchView(
                    state: .sealed,
                    slot: slot,
                    pills: $pills,
                    gravity: motionEngine.gravity
                )
                .frame(width: pouchSize.width, height: pouchSize.height)
                .id(resetToken)
                Spacer()
                controls
                Text("Stage 3 — motion + physics")
                    .font(PPFont.caption)
                    .foregroundStyle(PPColor.textSecondary)
                    .padding(.bottom, PPSpacing.lg)
            }
        }
        .onAppear {
            regeneratePills()
            motionEngine.start()
        }
        .onDisappear {
            motionEngine.stop()
        }
        .onChange(of: pillCount) { _, _ in regeneratePills() }
        .onChange(of: mix) { _, _ in regeneratePills() }
        .onChange(of: motionMode) { _, newMode in
            if let mock = motionEngine as? MotionEngineMock {
                mock.mode = newMode
            }
        }
        .onChange(of: manualGravityX) { _, _ in updateManualGravity() }
        .onChange(of: manualGravityY) { _, _ in updateManualGravity() }
    }

    @ViewBuilder
    private var controls: some View {
        VStack(spacing: PPSpacing.sm) {
            Picker("슬롯", selection: $slot) {
                Text("아침").tag(TimeSlot.morning)
                Text("점심").tag(TimeSlot.lunch)
                Text("저녁").tag(TimeSlot.evening)
            }
            .pickerStyle(.segmented)

            HStack(spacing: PPSpacing.sm) {
                Text("알약 \(Int(pillCount))개")
                    .font(PPFont.caption)
                    .foregroundStyle(PPColor.textSecondary)
                    .frame(width: 70, alignment: .leading)
                Slider(value: $pillCount, in: 0 ... 8, step: 1)
            }

            HStack(spacing: PPSpacing.sm) {
                Picker("조합", selection: $mix) {
                    ForEach(PillMix.allCases) { m in
                        Text(m.displayName).tag(m)
                    }
                }
                .pickerStyle(.menu)
                Spacer()
                Button("Reset") {
                    resetToken &+= 1
                    regeneratePills()
                }
                .font(PPFont.caption)
                .buttonStyle(.bordered)
            }

            if motionEngine is MotionEngineMock {
                motionControls
            }
        }
        .padding(.horizontal, PPSpacing.lg)
    }

    @ViewBuilder
    private var motionControls: some View {
        Divider().padding(.vertical, PPSpacing.xs)
        Picker("motion", selection: $motionMode) {
            Text("Auto").tag(MotionEngineMock.Mode.auto)
            Text("Manual").tag(MotionEngineMock.Mode.manual)
        }
        .pickerStyle(.segmented)

        if motionMode == .manual {
            HStack(spacing: PPSpacing.sm) {
                Text("X \(String(format: "%.2f", manualGravityX))")
                    .font(PPFont.caption.monospacedDigit())
                    .foregroundStyle(PPColor.textSecondary)
                    .frame(width: 70, alignment: .leading)
                Slider(value: $manualGravityX, in: -1 ... 1)
            }
            HStack(spacing: PPSpacing.sm) {
                Text("Y \(String(format: "%.2f", manualGravityY))")
                    .font(PPFont.caption.monospacedDigit())
                    .foregroundStyle(PPColor.textSecondary)
                    .frame(width: 70, alignment: .leading)
                Slider(value: $manualGravityY, in: -1 ... 1)
            }
        }
    }

    private func regeneratePills() {
        let bounds = PouchView.pillBounds(in: pouchSize)
        pills = PillBody.mock(count: Int(pillCount), mix: mix, bounds: bounds)
    }

    private func updateManualGravity() {
        if let mock = motionEngine as? MotionEngineMock {
            mock.manualGravity = SIMD2(manualGravityX, manualGravityY)
        }
    }
}

#Preview("Showcase · light") {
    PouchShowcaseView().preferredColorScheme(.light)
}
