# Zoisite

하드웨어 PMU 및 명령어 퇴장 원격 측정 감사기 (Hardware PMU & Instruction-Retired Telemetry Auditor)

순수 Zig로 작성된 하드웨어 성능 모니터링 유닛(Performance Monitoring Unit, PMU) 및 명령어 퇴장(instructions-retired) 텔레메트리 감사 라이브러리입니다.

[English Documentation](README.md)

## 개요

`clock_gettime`이나 벽시계 타이머와 같은 소프트웨어 타이밍 메커니즘은 운영체제 스케줄링 지터 및 CPU 주파수 스케일링 노이즈의 영향을 받습니다. Zoisite는 커널 추상화를 우회하고 엄격한 직렬화 배리어가 포함된 인라인 어셈블리를 통해 하드웨어 프로세서 성능 카운터를 직접 읽어냅니다.

## 아키텍처

- **하드웨어 사이클 판독기**:
  - `x86_64`: 비순차적 실행(out-of-order execution) 파이프라인을 비우기 위해 `cpuid` 직렬화 배리어가 선행된 `rdtsc`를 방출합니다.
  - `AArch64`: 인스트럭션 동기화 배리어(`isb`)가 선행된 `cntvct_el0` 가상 카운터 판독을 방출합니다.
- **메트릭 계산**: 진정한 프로세서 마이크로 아키텍처 메트릭을 계산합니다:
  - 총 경과 CPU 사이클 수.
  - 명령어당 사이클 수 (CPI).
  - 사이클당 명령어 수 (IPC).
- **OS 오버헤드 제로**: 핫 루프 벤치마킹 도중 발생하는 시스템 콜 오버헤드를 완전히 제거합니다.

## 빌드 및 사용법

```bash
# 단위 테스트 실행
zig build test

# 최적화 바이너리 빌드
zig build -Doptimize=ReleaseFast

# 샘플 커널(100,000회 반복)에 대한 하드웨어 PMU 감사 실행
./zig-out/bin/zoisite audit 100000
```

## 라이선스

MIT License. Copyright (c) 2026 Jeong Hoon Kim.
