#!/bin/bash
# quality-gate.template.sh — 프로젝트별 품질 게이트 템플릿
#
# 사용법:
#   cp templates/quality-gate.template.sh <PROJECT>/.orbit/quality-gate.sh
#   chmod +x <PROJECT>/.orbit/quality-gate.sh
#   게이트 명령을 아래 섹션에 채운다.
#
# 반환값:
#   exit 0 → pass (SubagentStop 계속)
#   exit 1 → fail (hooks/quality-gate.sh 가 block JSON 출력 → SubagentStop 차단)
#
# hooks/quality-gate.sh 래퍼가 이 스크립트를 호출한다.
# base 플러그인은 특정 빌드 도구를 모르므로 이 파일을 프로젝트가 채운다.

# --- 아래를 프로젝트에 맞게 수정 ---

# 기본: no-op pass (아무 게이트 없음)
exit 0

# Next.js 예시:
# set -euo pipefail
# cd "${CLAUDE_PROJECT_DIR}"
# npm run -s typecheck 2>&1 || exit 1
# npm run -s lint 2>&1 || exit 1
# exit 0

# Rust 예시:
# cd "${CLAUDE_PROJECT_DIR}"
# cargo check 2>&1 || exit 1
# exit 0
