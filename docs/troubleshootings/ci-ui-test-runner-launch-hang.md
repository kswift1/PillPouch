# ci-ui-test-runner-launch-hang.md — UI 테스트 runner launch 실패 시 CI hang

## 증상

`xcodebuild test`가 UI 테스트 runner(`PillPouchUITests-Runner.app`) launch 시점에 hang. CI 러너의 `timeout-minutes: 30` 도달하면 `##[error]The operation was canceled.`로 강제 취소.

로컬에서는 동일 launch 실패 후 시뮬레이터가 운 좋게 재시도에 성공하면 회복 가능 (관측: 432초 후 회복). CI 러너는 시뮬레이터 환경이 더 빈약하여 회복 불가.

## 표면

```
PillPouchUITests-Runner setup 완료 → 그 다음 27분간 출력 0
##[error]The operation was canceled.
```

내부적으로 `Simulator device failed to launch com.co.sungwon.PillPouchUITests.xctrunner` + `RequestDenied` 에러가 발생하지만 xcodebuild가 retry loop에 빠져 stdout으로 노출 안 됨.

## 원인

Xcode가 새 프로젝트 생성 시 자동으로 추가하는 **UI 테스트 boilerplate** 두 메서드가 시뮬레이터 launch에 의존:

```swift
func testExample() throws {
    let app = XCUIApplication()
    app.launch()
}

func testLaunchPerformance() throws {
    measure(metrics: [XCTApplicationLaunchMetric()]) {
        XCUIApplication().launch()
    }
}
```

- `testLaunchPerformance`는 `measure`가 기본 10회 반복 launch — 시뮬레이터가 첫 launch에 실패하면 retry loop 누적
- 두 메서드 모두 **assertion 0** — 빌드 단계가 이미 검증하는 내용이라 검증 가치 없음

## 해결 (W1-10에서 적용)

UI 테스트 target을 통째로 제거. 다음 4가지를 한 PR에 묶음:

1. **소스 파일 삭제**: `ios/PillPouchUITests/PillPouchUITests.swift`, `ios/PillPouchUITests/PillPouchUITestsLaunchTests.swift`
2. **`ios/PillPouchUITests/` 디렉토리 통째로 사라짐** (마지막 파일 git rm 시 자동)
3. **`ios/PillPouch.xcodeproj/project.pbxproj`에서 UI 테스트 target 관련 객체 모두 제거**:
   - PBXContainerItemProxy / PBXFileReference / PBXFileSystemSynchronizedRootGroup
   - PBXFrameworksBuildPhase / PBXResourcesBuildPhase / PBXSourcesBuildPhase (UI tests용)
   - PBXNativeTarget / PBXTargetDependency (UI tests용)
   - PBXProject targets/TargetAttributes 목록에서 UI tests target 참조
   - PBXGroup children (root 그룹 + Products 그룹) 참조
   - XCBuildConfiguration Debug/Release + XCConfigurationList (UI tests용)
4. **로컬 검증**: `xcodebuild -list`에서 `PillPouchUITests` 부재 확인 + `xcodebuild test`가 39초 내 완료(이전 432초)

## 재발 방지

- **UI 테스트 신규 추가 시 boilerplate 패턴 금지** — 의미 있는 케이스가 있을 때만 target 신설.
- **W2(드래그 인터랙션) / W4(주간 뷰 navigation)** 시점에 진짜 UI 테스트 target 재생성. 그땐 시뮬레이터 launch가 실제 검증의 일부이므로 hang ≠ 무의미.
- Xcode 자동 생성 boilerplate 살려두기 X — `Item.swift` 제거(W1-10)와 같은 결.

## 관련 파일

- `docs/conventions/code-style.md` (코드 스타일 룰)
- W1-10 PR #13 (https://github.com/kswift1/PillPouch/pull/13)

## 변경 이력

- 2026-04-28: 초기 작성 (W1-10 CI 첫 실패 후 진단 및 해결)
