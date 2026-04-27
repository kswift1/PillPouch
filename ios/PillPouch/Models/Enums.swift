//
//  Enums.swift
//  PillPouch
//

import Foundation

/// 봉지 안 캡슐의 시각적 형태 — 기획서 §캡슐 일러스트 6종.
/// 봉지 SVG 렌더링과 영양제 등록 화면 Picker에서 사용.
enum CapsuleType: String, Codable, CaseIterable {
    case tablet, softgel, capsule, powder, liquid, gummy
}

/// 하루 3슬롯 — 기획서 §화면 구조 §데이터 모델 스케치.
/// `UserSettings`의 시각과 1:1 매핑되며 Today 화면의 봉지 띠 순서를 결정.
enum TimeSlot: String, Codable, CaseIterable {
    case morning, lunch, evening
}

/// 슬롯에 대한 사용자 행동 결과 — 기획서 §봉지 상태 5종 중 데이터 측 3종.
/// `taken` = 찢김, `skipped` = 길게 누르기 → 건너뛰기, `missed` = 시간 지남 후 미체크.
enum IntakeStatus: String, Codable, CaseIterable {
    case taken, missed, skipped
}
