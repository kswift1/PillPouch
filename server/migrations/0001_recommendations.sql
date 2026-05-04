-- 인구통계 기반 권장 영양제 정보 (Identity Anti-Promise §4 정합)
-- 개인 진단 X / 인구통계 일반 권장만. 작업지시자 큐레이션 + 식약처 KDRIs 기반.
-- 갱신은 server/seed/recommendations.json commit + Fly.io 자동 배포로.
CREATE TABLE recommendations (
    -- 카테고리 식별자 (예: male_20s_30s)
    category TEXT NOT NULL PRIMARY KEY,
    -- 사용자에게 보여지는 이름 (예: "20~30대 남성")
    display_name TEXT NOT NULL,
    -- 권장 영양제 목록 JSON (Supplement[])
    -- [{"name":"비타민D","reason":"한국인 평균 부족","priority":1}, ...]
    supplements_json TEXT NOT NULL,
    -- 데이터 출처 (예: "식약처 KDRIs / 한국영양학회 / WebSearch 2026-05-04")
    source TEXT NOT NULL,
    -- 면책 문구 (예: "인구통계 기반 일반 정보. 개인 진단·처방 X.")
    disclaimer TEXT NOT NULL,
    -- Unix epoch seconds, 갱신 시점 추적
    updated_at INTEGER NOT NULL
);
