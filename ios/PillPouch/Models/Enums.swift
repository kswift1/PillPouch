//
//  Enums.swift
//  PillPouch
//

import Foundation

/// 하루 3슬롯 — 기획서 §화면 구조 §데이터 모델 스케치.
/// `UserSettings`의 시각과 1:1 매핑되며 Today 화면의 봉지 띠 순서를 결정.
enum TimeSlot: String, Codable, CaseIterable {
    /// 아침 슬롯. `UserSettings.morningHour/Minute` 사용.
    case morning

    /// 점심 슬롯. `UserSettings.lunchHour/Minute` 사용.
    case lunch

    /// 저녁 슬롯. `UserSettings.eveningHour/Minute` 사용.
    case evening
}

/// 알약의 물리적 형태 — 기획서 §데이터 모델 스케치.
/// 봉지 안 시각 표현 분기에 사용. 디자이너 일러스트(#11)가 머지되면 PillView 내부만 교체.
enum CapsuleType: String, Codable, CaseIterable {
    /// 정제. 둥근 단단한 약. Circle + 가장자리 ring.
    case tablet

    /// 연질 캡슐. 광택 있는 타원. 오메가3 등.
    case softgel

    /// 경질 캡슐. 두 톤 양 끝 마감. 종합비타민 등.
    case capsule

    /// 가루. 미세 입자 군집. 분말 비타민 등.
    case powder

    /// 액상. 봉지 모델로 표현 X — V1 미지원, 마커만.
    case liquid

    /// 젤리. 반투명 rounded square. 어린이용 비타민 등.
    case gummy
}

/// 슬롯에 대한 사용자 행동 결과 — 기획서 §봉지 상태 5종 중 데이터 측 3종.
/// `taken` = 찢김, `skipped` = 길게 누르기 → 건너뛰기, `missed` = 시간 지남 후 미체크.
enum IntakeStatus: String, Codable, CaseIterable {
    /// 찢김. 사용자가 봉지를 찢어 복용을 기록한 상태 — 가설 B의 비가역 증거.
    case taken

    /// 누락. 슬롯 시간이 지났는데 어떤 행동도 없는 상태.
    case missed

    /// 건너뜀. 길게 누르기 메뉴에서 명시적으로 건너뛴 상태.
    case skipped
}
