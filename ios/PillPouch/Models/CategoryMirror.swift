//
//  CategoryMirror.swift
//  PillPouch
//

import Foundation
import SwiftData

/// 서버 카탈로그(영양제 카테고리)의 클라이언트 mirror.
/// 첫 실행 시 번들 시드(JSON 12 row)에서 import, 이후 서버 동기화로 갱신.
/// `Supplement.categoryKey`가 본 모델의 `key`를 참조 (clientside FK).
/// 서버 SoT — 본 mirror는 read-only 캐시 (사용자 직접 편집 X).
///
/// 결정 박제: ADR-0007 (`docs/adr/0007-server-catalog-as-source-of-truth.md`).
@Model
final class CategoryMirror {
    /// 서버 카탈로그 PRIMARY KEY (lowerCamel, 예: `"vitaminD"`, `"omega3"`).
    @Attribute(.unique) var key: String

    /// 한글 표시명 (예: `"비타민 D"`). 서버에서 내려오는 사용자 노출 텍스트.
    var displayName: String

    /// 다운로드된 이미지의 로컬 파일 path. 미다운로드 시 `nil` → `iconRemoteURL` fallback.
    var iconLocalPath: String?

    /// 서버 hosting 이미지 URL (Fly static, ADR-0008).
    var iconRemoteURL: URL

    /// 검색/리스트 UI 정렬 순서. 작을수록 위.
    var displayOrder: Int

    /// 서버 카탈로그 row 버전 (`since` 파라미터 기반 cache invalidation).
    var version: Int

    /// 마지막 동기화 시각.
    var updatedAt: Date

    init(
        key: String,
        displayName: String,
        iconLocalPath: String? = nil,
        iconRemoteURL: URL,
        displayOrder: Int,
        version: Int,
        updatedAt: Date = .now
    ) {
        self.key = key
        self.displayName = displayName
        self.iconLocalPath = iconLocalPath
        self.iconRemoteURL = iconRemoteURL
        self.displayOrder = displayOrder
        self.version = version
        self.updatedAt = updatedAt
    }
}
