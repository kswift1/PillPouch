# apns-cert-setup.md — APNs Auth Key (.p8) 셋업

> **Status**: stub. **W3에서 채움** (백엔드 + APNs 통합 시점).

## 채워야 할 항목

### 1. Apple Developer Portal에서 .p8 발급
- [ ] Membership 확인 (Team ID)
- [ ] Certificates, Identifiers & Profiles → Keys → +
- [ ] APNs 권한 활성화
- [ ] Key ID 확보 (10자)
- [ ] `.p8` 파일 다운로드 (한 번만 가능 — **즉시 안전한 곳에 백업**)

### 2. Bundle ID 등록
- [ ] App ID 생성 (`com.<your-domain>.pillpouch` — **소문자 강제**, 기획서 §백엔드 도입 시 유의사항 §1)
- [ ] Push Notifications capability 활성화
- [ ] Live Activity 지원 (iOS 17.2+ PTS 자동 사용)

### 3. 키 보관
- [ ] `.p8` 원본은 1Password 또는 macOS Keychain (절대 git X, `.gitignore`에 `*.p8` 강제)
- [ ] Fly.io에 주입: `fly secrets set APNS_KEY_PATH=/secrets/AuthKey_XXX.p8` + 파일 마운트
- [ ] 환경 변수: `APNS_KEY_ID`, `APNS_TEAM_ID`, `APNS_BUNDLE_ID`, `APNS_ENV` (sandbox/production)

### 4. push topic 형식
- Live Activity용: `{bundleID}.push-type.liveactivity`
- 일반 푸시: `{bundleID}`
- Bundle ID에 대문자 들어가면 **Topic Mismatch 에러** (기획서 경고)

### 5. 검증
- [ ] APNs sandbox로 로컬 디바이스에 테스트 푸시 발송
- [ ] 응답 코드 200 확인
- [ ] BadDeviceToken / Unregistered / TooManyProviderTokenUpdates 처리 코드

## 위험 메모
- `.p8`은 한 번만 다운로드 가능 — 분실 시 새 키 발급 필요 (기존 키는 revoke)
- Sandbox vs Production 키 별도 (TestFlight = production)
- iOS 18.x PTS 토큰 발급 이슈 알려져 있음 — `ios-pts-debug.md` 참조

## 참고
- ADR-0001 (Rust + Axum 백엔드)
- 기획서 §백엔드 도입 시 유의사항 §1 인증서/프로비저닝
