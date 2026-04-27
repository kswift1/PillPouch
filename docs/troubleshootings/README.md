# troubleshootings/ — 문제 해결 기록

**해결한 후** 작성. 미해결 사항은 GitHub Issue로 추적.

## 파일명
자유. 증상 중심 (`ios18-pts-token-missing.md`, `apns-bad-device-token.md` 등)

## 형식

```markdown
# 증상 한 줄

## 환경
iOS 18.2 / Xcode 16.1 / 실기기 iPhone 15 Pro / 2026-MM-DD

## 재현 절차
1. ...
2. ...

## 발견 단서
- 로그: ...
- 응답: ...

## 원인
근본 원인 (가설이면 가설로 명시)

## 해결책
- 정공법
- (적용 안 되면) 우회

## 향후 대응
- runbook 업데이트?
- ADR 필요?
- 회귀 방지 테스트?
```

## 사용 시점
- 막혔던 문제를 풀고 나서 즉시 (잊기 전에)
- 비슷한 증상 재발 시 가장 먼저 확인하는 곳
