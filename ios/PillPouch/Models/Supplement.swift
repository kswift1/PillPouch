//
//  Supplement.swift
//  PillPouch
//

import Foundation
import SwiftData

/// 사용자가 등록한 영양제 1종. 봉지 띠의 한 칸에 대응.
/// 삭제 시 관련 `IntakeSchedule`/`IntakeLog`는 cascade로 함께 제거.
///
/// `categoryKey`는 서버 카탈로그(`CategoryMirror.key`) row의 lowerCamel 식별자.
/// 예: `"vitaminD"`, `"omega3"`. 12종 시드 + 서버 동적 추가 카테고리 모두 같은 형식.
/// 자세한 내용은 ADR-0007 (`docs/adr/0007-server-catalog-as-source-of-truth.md`).
@Model
final class Supplement {
    /// CloudKit 동기화 시 충돌 해소 키. `@Attribute(.unique)`로 중복 방지.
    @Attribute(.unique) var id: UUID

    /// 사용자 표시 이름 (예: "비타민D 1000IU"). 카테고리 표시명과 별개 — 사용자가 자유 입력.
    var name: String

    /// 서버 카탈로그 row의 lowerCamel key 참조 (clientside FK, 예: `"vitaminD"`).
    /// 카테고리 표시명/이미지는 `CategoryMirror`에서 조회. mirror에 없으면 fallback 표시.
    var categoryKey: String

    /// 디자인 시스템 색 토큰 식별자 (W1-4 결과물 참조). 미지정 시 슬롯 색조 사용.
    var colorToken: String?

    /// 등록 시각 — 정렬 + 디버깅용.
    var createdAt: Date

    /// 이 영양제의 슬롯별 복용 스케줄. Supplement 삭제 시 cascade.
    @Relationship(deleteRule: .cascade, inverse: \IntakeSchedule.supplement)
    var schedules: [IntakeSchedule] = []

    /// 이 영양제의 복용 기록 누적. Supplement 삭제 시 cascade.
    @Relationship(deleteRule: .cascade, inverse: \IntakeLog.supplement)
    var logs: [IntakeLog] = []

    init(
        id: UUID = UUID(),
        name: String,
        categoryKey: String,
        colorToken: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.categoryKey = categoryKey
        self.colorToken = colorToken
        self.createdAt = createdAt
    }
}
