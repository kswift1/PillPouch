-- ADR-0007 + #17 결과: V1.0 영양제 카테고리 16종.
-- updated_at = 2026-04-28T15:01:16Z (#17 close / PR #22 merge 시점).
INSERT INTO category (key, display_name, icon_path, display_order, version, updated_at)
VALUES
    ('omega3', '오메가-3', '/assets/category-icons/omega3.png', 1, 1, 1777388476),
    ('probiotics', '유산균', '/assets/category-icons/probiotics.png', 2, 1, 1777388476),
    ('vitaminC', '비타민 C', '/assets/category-icons/vitaminC.png', 3, 1, 1777388476),
    ('multivitamin', '종합 비타민', '/assets/category-icons/multivitamin.png', 4, 1, 1777388476),
    ('vitaminD', '비타민 D', '/assets/category-icons/vitaminD.png', 5, 1, 1777388476),
    ('vitaminB', '비타민 B', '/assets/category-icons/vitaminB.png', 6, 1, 1777388476),
    ('milkThistle', '밀크씨슬', '/assets/category-icons/milkThistle.png', 7, 1, 1777388476),
    ('glucosamine', '글루코사민', '/assets/category-icons/glucosamine.png', 8, 1, 1777388476),
    ('lutein', '루테인', '/assets/category-icons/lutein.png', 9, 1, 1777388476),
    ('collagen', '콜라겐', '/assets/category-icons/collagen.png', 10, 1, 1777388476),
    ('magnesium', '마그네슘', '/assets/category-icons/magnesium.png', 11, 1, 1777388476),
    ('calcium', '칼슘', '/assets/category-icons/calcium.png', 12, 1, 1777388476),
    ('iron', '철분', '/assets/category-icons/iron.png', 13, 1, 1777388476),
    ('zinc', '아연', '/assets/category-icons/zinc.png', 14, 1, 1777388476),
    ('coq10', '코엔자임 Q10', '/assets/category-icons/coq10.png', 15, 1, 1777388476),
    ('other', '기타', '/assets/category-icons/other.png', 99, 1, 1777388476)
ON CONFLICT(key) DO UPDATE SET
    display_name = excluded.display_name,
    icon_path = excluded.icon_path,
    display_order = excluded.display_order,
    version = excluded.version,
    updated_at = excluded.updated_at;
