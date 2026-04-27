# Xcode 26이 IPHONEOS_DEPLOYMENT_TARGET을 26.4로 자동 설정 — CI(Xcode 16.4)에서 destination 매칭 실패

## 환경
- 로컬: macOS 26.3.1 + Xcode 26.4
- CI: GitHub Actions `macos-15` + Xcode 16.4
- 발생일: 2026-04-27 (PR #2, Issue #1)

## 재현 절차
1. Xcode 26.4에서 새 프로젝트 생성 (Pill Pouch)
2. `IPHONEOS_DEPLOYMENT_TARGET`이 자동으로 **26.4**로 박힘 (`project.pbxproj` 4곳)
3. CI(Xcode 16.4 macos-15 runner)에서 `xcodebuild test` 실행
4. 시뮬은 충분히 있음 (`Available iPhone (iOS) simulators: 42`, iPhone 16 Pro 잡힘)
5. 그러나 결과:
   ```
   xcodebuild: error: Unable to find a destination matching the provided destination specifier:
       { id:12464C08-1EBB-45FF-A9CE-AD6B611CC6A9 }   ← iPhone 16 Pro

       Available destinations for the "PillPouch" scheme:
           { platform:iOS Simulator, ... placeholder ... }
           { platform:visionOS Simulator, ... } × 5    ← visionOS만 보임
   ```

## 발견 단서
- `xcodebuild -showBuildSettings`로 확인:
  ```
  IPHONEOS_DEPLOYMENT_TARGET = 26.4
  RECOMMENDED_IPHONEOS_DEPLOYMENT_TARGET = 15.0
  SDKROOT = .../SDKs/iPhoneOS26.4.sdk
  ```
- 즉, 프로젝트가 **iOS 26.4 SDK + 26.4 deployment target**을 요구
- macos-15 runner의 Xcode 16.4는 iOS 18 SDK까지만 보유 → **scheme의 deployment target과 호환되는 시뮬이 0개** (iPhone 16 Pro는 iOS 18.x runtime이라 26.4 미만 → 호환 안 됨)
- 그래서 simctl엔 시뮬 42개 보이지만 xcodebuild의 "Available destinations"엔 iOS Simulator 카테고리 비어있음
- visionOS는 별도 SDK라 destination에는 보이지만 PillPouch scheme이 visionOS 빌드 안 함 → 실제 사용 불가

## 원인
Xcode 26.4가 새 프로젝트 생성 시 **현재 SDK 버전(26.4)을 deployment target의 default로 자동 설정**.
이는 일반적으로 잘못된 default — 보통 `RECOMMENDED_IPHONEOS_DEPLOYMENT_TARGET = 15.0` 같은 더 보수적 값을 권장.

기획서(`docs/brief.md` §기술 스택)는 **iOS 17.2+** (Push to Start 전제). Xcode가 자동으로 더 높은 값을 박아도 실제 코드는 17.2부터 동작 가능.

## 해결책

### Deployment target을 17.2로 명시 (정공법)

`ios/PillPouch.xcodeproj/project.pbxproj`에서 4곳 모두 변경:
```
IPHONEOS_DEPLOYMENT_TARGET = 26.4;  →  IPHONEOS_DEPLOYMENT_TARGET = 17.2;
```

검증:
```bash
xcodebuild -project ios/PillPouch.xcodeproj -scheme PillPouch \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest' \
  CODE_SIGNING_ALLOWED=NO build
# ** BUILD SUCCEEDED **
```

CI(Xcode 16.4)에서도 iOS 18 시뮬이 17.2 deployment target과 호환되므로 destination 인식됨.

## 향후 대응
- **새 프로젝트 추가 시 항상 deployment target 확인** — Xcode 26+가 자동으로 너무 높은 값을 박을 수 있음
- pre-commit hook 또는 CI step으로 `IPHONEOS_DEPLOYMENT_TARGET`이 17.2 미만/이상 인지 검증 추가 검토 (W3 폴리싱)
- `objectVersion = 77`은 Xcode 16+에서 도입 — Xcode 16.4도 읽을 수 있음. 더 새 format으로 올라가면(Xcode 26 전용 format 도입 시) runner를 macos-26으로 갈아야 할 수 있음. 그땐 별도 ADR.

## 참고
- Apple Developer: [Setting the deployment target](https://developer.apple.com/documentation/xcode/configuring-build-settings-for-a-platform)
- 기획서 §기술 스택: iOS 17.2+ (Push to Start 전제)
