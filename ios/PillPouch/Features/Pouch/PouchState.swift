//
//  PouchState.swift
//  PillPouch
//

import Foundation

/// 봉지의 시각·인터랙션 상태. 기획서 §봉지 상태 5종 중 V1 핵심 2개 + 진행 중 상태.
/// Skipped/Missed는 별도 task에서 추가 예정.
enum PouchState: Equatable {
    /// 봉인됨. 윗부분 V컷만 표시, 알약은 봉지 안 정착.
    case sealed

    /// 찢는 중. `progress` 0.0~1.0. 시각 단계는 0~30%, 30~70%, 70~100%로 분기.
    case tearing(progress: Double)

    /// 찢김. 윗 조각이 살짝 매달린 채 고정. 후속 stage에서 알약 낙하.
    case torn
}
