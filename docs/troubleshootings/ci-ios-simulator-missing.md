# CI에서 `xcodebuild test`가 "Unable to find a destination" 에러로 실패

## 환경
- GitHub Actions `macos-15` runner
- Xcode 16.4 (`/Applications/Xcode_16.4.app`)
- 발생일: 2026-04-27 (PR #2, Issue #1 첫 CI)

## 재현 절차
1. `.github/workflows/ios-build.yml`에서 `xcrun simctl` jq 쿼리로 첫 iPhone 시뮬 ID 선택
2. `xcodebuild test -destination "id=<SIM_ID>"` 실행
3. 결과:
   ```
   xcodebuild: error: Unable to find a destination matching the provided destination specifier:
       { id:12464C08-1EBB-45FF-A9CE-AD6B611CC6A9 }
   Available destinations for the "PillPouch" scheme:
       { platform:visionOS Simulator, ... variant:Designed for [iPad,iPhone], ... name:Apple Vision Pro }
       ...
   ```
4. **Available 목록에 iOS Simulator 0개** — visionOS만 존재

## 발견 단서
- Runner image의 Xcode 16.4에 **iOS Simulator runtime이 미리 설치 안 됨** (image 정책 변동 또는 누락)
- 동시에 jq 쿼리 `select(.key | contains("iOS"))`가 **visionOS도 매칭** — `com.apple.CoreSimulator.SimRuntime.visionOS-2-3` 키에 "iOS" substring 포함 (visionOS의 "iOS" 부분)
- 그래서 잘못된 visionOS "Apple Vision Pro (Designed for iPhone)" 디바이스 ID가 첫 번째로 선택됨
- 그 ID는 PillPouch scheme(iOS deployment target)과 매칭 안 됨 → `Unable to find a destination`

## 원인
1차 원인: jq 쿼리가 visionOS 시뮬을 잘못 매칭 (substring match가 너무 느슨)
2차 원인: runner image에 iOS Simulator runtime 부재 (image 변동성)

## 해결책

### 1. jq 쿼리 강화 (정공법)
`contains("iOS")` → `test("SimRuntime\\.iOS-")` (정규식 prefix 매칭)
이러면 `SimRuntime.iOS-18-2`만 매칭, `SimRuntime.visionOS-2-3` 배제.

### 2. iOS Simulator runtime 자동 다운로드 (보험)
시뮬이 0개면 `xcodebuild -downloadPlatform iOS`로 다운로드.
Runner image 변동 흡수.

### 적용 워크플로우 (`.github/workflows/ios-build.yml`)

```yaml
- name: Ensure iOS Simulator runtime
  run: |
    HAS_IOS=$(xcrun simctl list devices available -j \
      | jq '[.devices | to_entries[] | select(.key | test("SimRuntime\\.iOS-")) | .value[] | select(.name | startswith("iPhone"))] | length')
    if [ "$HAS_IOS" -eq 0 ]; then
      sudo xcodebuild -runFirstLaunch
      xcodebuild -downloadPlatform iOS
    fi

- name: Pick first available iPhone simulator
  id: sim
  run: |
    SIM_ID=$(xcrun simctl list devices available -j \
      | jq -r '[.devices | to_entries[] | select(.key | test("SimRuntime\\.iOS-")) | .value[] | select(.name | startswith("iPhone")) | .udid] | first')
    if [ -z "$SIM_ID" ] || [ "$SIM_ID" = "null" ]; then
      xcrun simctl list devices
      exit 1
    fi
    echo "sim_id=$SIM_ID" >> "$GITHUB_OUTPUT"
```

## 향후 대응
- macOS runner image 변경 시 시뮬 환경이 또 바뀔 수 있음. `Ensure iOS Simulator runtime` step이 보험으로 작동.
- 로컬 환경(Xcode 26.4)과 CI(Xcode 16.4)의 OS 차이가 커지면 deployment target/SDK 호환성 추가 검증 필요.
- 시뮬 다운로드는 한 번 실행 시 5~10분 추가 — runner image 갱신 후 첫 PR에서만 발생, 그 후 캐시.

## 참고
- jq의 `contains` vs `test` 차이: `contains`는 substring, `test`는 정규식. 정확한 prefix 매칭이 필요할 땐 `test("^...")` 또는 `startswith`.
- GitHub macos runner Xcode 사전 설치 목록: https://github.com/actions/runner-images/blob/main/images/macos/macos-15-Readme.md
