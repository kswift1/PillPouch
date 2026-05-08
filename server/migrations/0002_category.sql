-- 영양제 카테고리 카탈로그 (ADR-0007 서버 SoT)
-- V1.0은 16종 시드 + Fly static 이미지 hosting.
CREATE TABLE category (
    -- lowerCamel 식별자 (예: omega3, vitaminD, milkThistle)
    key TEXT NOT NULL PRIMARY KEY,
    -- 사용자에게 보여지는 이름 (예: "오메가-3")
    display_name TEXT NOT NULL,
    -- 정적 이미지 경로 (예: "/assets/category-icons/omega3.png")
    icon_path TEXT NOT NULL,
    -- 검색/표시 정렬 순서
    display_order INTEGER NOT NULL,
    -- 서버 카탈로그 변경 버전. 클라이언트는 since={version}으로 증분 동기화.
    version INTEGER NOT NULL,
    -- Unix epoch seconds, 갱신 시점 추적
    updated_at INTEGER NOT NULL
);

CREATE INDEX idx_category_display_order ON category(display_order);
CREATE INDEX idx_category_version ON category(version);
