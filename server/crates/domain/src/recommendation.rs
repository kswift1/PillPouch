//! 인구통계 기반 권장 영양제 도메인 타입.
//!
//! Identity Anti-Promise §4 정합:
//! - 개인 진단 / 처방 / 자문 X
//! - 인구통계 평균 권장만 (식약처 KDRIs / 한국영양학회 기준)
//!
//! 데이터 소스: 작업지시자 큐레이션 + 식약처 + WebSearch.
//! repo `server/seed/recommendations.json` → 빌드/배포 시 DB import.

use serde::{Deserialize, Serialize};
use thiserror::Error;

/// 카테고리별 권장 영양제 묶음.
///
/// `category` = 식별자 (예: `male_20s_30s`).
/// `display_name` = 한국어 표시 (예: `"20~30대 남성"`).
/// `supplements` = 권장 영양제 목록 (정렬 보존).
/// `source` = 데이터 출처 (예: `"식약처 KDRIs / 한국영양학회 / WebSearch 2026-05-04"`).
/// `disclaimer` = Anti-Promise §4 면책 (예: `"인구통계 기반 일반 정보. 개인 진단·처방 X."`).
/// `updated_at` = Unix epoch seconds, 갱신 시점.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct Recommendation {
    pub category: String,
    pub display_name: String,
    pub supplements: Vec<Supplement>,
    pub source: String,
    pub disclaimer: String,
    pub updated_at: i64,
}

/// 한 영양제 항목.
///
/// `name` = 영양제 이름 (예: `"비타민D"` / `"오메가3"` / `"엽산 600μg"`).
/// `reason` = 권장 이유 한 줄 (예: `"한국인 평균 부족, 골 건강"`).
/// `priority` = 카테고리 안 우선순위 (1 = 최우선). 동일 priority 허용.
///
/// 확장 optional 필드 (V1, 후방 호환):
/// `description` = 2~3문장 상세 설명.
/// `dosage` = 권장 복용량 (예: `"남성 1000mg/일"`).
/// `timing` = 복용 시기 (예: `"식후 30분"`).
/// `side_effects` = 부작용·주의사항. **Anti-Promise §2 정합**: 일반 정보,
/// 개인 체질·증상별 차이 가능, 전문가 상담 권장 톤으로 작성.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct Supplement {
    pub name: String,
    pub reason: String,
    pub priority: u8,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub dosage: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub timing: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub side_effects: Option<String>,
}

/// 도메인 layer 에러.
///
/// Storage layer가 sqlx 에러를 본 enum으로 매핑해 api layer로 전달.
#[derive(Debug, Error)]
pub enum RecommendationError {
    #[error("category not found: {0}")]
    NotFound(String),
    #[error("invalid supplements_json: {0}")]
    InvalidJson(#[from] serde_json::Error),
    #[error("storage error: {0}")]
    Storage(String),
}

impl Recommendation {
    /// supplements를 priority 오름차순으로 정렬한 view 반환.
    /// 동일 priority면 입력 순서 보존 (stable sort).
    #[must_use]
    pub fn supplements_by_priority(&self) -> Vec<&Supplement> {
        let mut sorted: Vec<&Supplement> = self.supplements.iter().collect();
        sorted.sort_by_key(|s| s.priority);
        sorted
    }
}

#[cfg(test)]
#[allow(non_snake_case)] // 테스트 함수명은 한글 + 언더바 (CLAUDE.md / code-style.md §1)
mod tests {
    use super::{Recommendation, Supplement};

    fn 샘플_권장() -> Recommendation {
        Recommendation {
            category: "male_20s_30s".to_string(),
            display_name: "20~30대 남성".to_string(),
            supplements: vec![
                Supplement {
                    name: "비타민D".to_string(),
                    reason: "한국인 평균 부족".to_string(),
                    priority: 2,
                    description: None,
                    dosage: None,
                    timing: None,
                    side_effects: None,
                },
                Supplement {
                    name: "비타민B군".to_string(),
                    reason: "에너지 대사".to_string(),
                    priority: 1,
                    description: None,
                    dosage: None,
                    timing: None,
                    side_effects: None,
                },
                Supplement {
                    name: "마그네슘".to_string(),
                    reason: "스트레스".to_string(),
                    priority: 1,
                    description: None,
                    dosage: None,
                    timing: None,
                    side_effects: None,
                },
            ],
            source: "식약처 KDRIs".to_string(),
            disclaimer: "인구통계 기반 일반 정보. 개인 진단·처방 X.".to_string(),
            updated_at: 1_762_300_000,
        }
    }

    #[test]
    fn supplements_by_priority_가_priority_오름차순으로_정렬되며_동일_priority는_입력_순서_보존() {
        let r = 샘플_권장();
        let sorted = r.supplements_by_priority();

        assert_eq!(sorted.len(), 3);
        // priority 1 두 개가 입력 순서로 먼저 나옴 (B군 → 마그네슘)
        assert_eq!(sorted[0].name, "비타민B군");
        assert_eq!(sorted[1].name, "마그네슘");
        // priority 2 그 다음
        assert_eq!(sorted[2].name, "비타민D");
    }

    #[test]
    fn recommendation_serde_왕복으로_의미가_보존된다() {
        let r = 샘플_권장();
        let json = serde_json::to_string(&r).expect("serialize");
        let back: Recommendation = serde_json::from_str(&json).expect("deserialize");
        assert_eq!(r, back);
    }

    #[test]
    fn supplement_serde_왕복으로_의미가_보존된다() {
        let s = Supplement {
            name: "엽산 600μg".to_string(),
            reason: "임산부 식약처 5대 필수".to_string(),
            priority: 1,
            description: None,
            dosage: None,
            timing: None,
            side_effects: None,
        };
        let json = serde_json::to_string(&s).expect("serialize");
        let back: Supplement = serde_json::from_str(&json).expect("deserialize");
        assert_eq!(s, back);
    }

    #[test]
    fn 확장_필드가_None인_supplement_직렬화_시_optional_필드는_생략된다() {
        let s = Supplement {
            name: "비타민D".to_string(),
            reason: "한국인 평균 부족".to_string(),
            priority: 1,
            description: None,
            dosage: None,
            timing: None,
            side_effects: None,
        };
        let json = serde_json::to_string(&s).expect("serialize");
        // skip_serializing_if = "Option::is_none" 으로 None 필드 미출력 검증
        assert!(!json.contains("description"));
        assert!(!json.contains("dosage"));
        assert!(!json.contains("timing"));
        assert!(!json.contains("side_effects"));
    }

    #[test]
    fn 확장_필드가_없는_legacy_json도_default로_역직렬화된다() {
        // 기존 seed 형식 (확장 필드 없음) 호환 검증
        let legacy_json = r#"{"name":"비타민D","reason":"한국인 평균 부족","priority":1}"#;
        let s: Supplement = serde_json::from_str(legacy_json).expect("legacy deserialize");
        assert_eq!(s.description, None);
        assert_eq!(s.dosage, None);
        assert_eq!(s.timing, None);
        assert_eq!(s.side_effects, None);
    }

    #[test]
    fn 확장_필드가_채워진_supplement_왕복으로_의미가_보존된다() {
        let s = Supplement {
            name: "코엔자임Q10".to_string(),
            reason: "심혈관·항산화".to_string(),
            priority: 1,
            description: Some("미토콘드리아 에너지 생성에 핵심.".to_string()),
            dosage: Some("90~100mg/일 (식약처 인정)".to_string()),
            timing: Some("식후 30분, 지용성".to_string()),
            side_effects: Some("일반적으로 안전. 항응고제 상호작용 가능.".to_string()),
        };
        let json = serde_json::to_string(&s).expect("serialize");
        let back: Supplement = serde_json::from_str(&json).expect("deserialize");
        assert_eq!(s, back);
    }
}
