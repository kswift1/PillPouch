# data-model.md

> **Status**: stub. W1-3에서 SwiftData 모델 4종 정의 시 채움. W3에서 서버 SQLite 스키마 추가.

## 클라이언트 (SwiftData) — 예정
기획서 §데이터 모델 스케치 참조 (`brief.md`).

- `Supplement` (id, name, capsuleType, colorToken, createdAt)
- `IntakeSchedule` (supplementId, timeSlot, dose)
- `IntakeLog` (id, supplementId, timeSlot, takenAt, status)
- `UserSettings` (morningTime, lunchTime, eveningTime, timezone)

## 서버 (SQLite) — 예정
- `device_tokens` (user_id, pts_token, pu_token, timezone, last_seen_at)
- `push_log` (id, device_id, sent_at, status_code, payload_hash)

## TODO
- [ ] @Model 코드 + 마이그레이션 정책
- [ ] CloudKit 동기화 충돌 해결 룰 (W4)
- [ ] 서버 sqlx 마이그레이션 첫 버전 (W3)
