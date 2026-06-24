---
description: Initialize .orbit/ scaffold in the current project
argument-hint: "[project-dir] — defaults to current working directory"
allowed-tools: [Bash, Read, Write]
---

# /orbit-init — 프로젝트 orbit 초기화

현재 프로젝트 루트에 `.orbit/` 디렉토리와 설정 파일을 스캐폴딩한다.

## 실행 절차

### Step 1: 프로젝트 루트 결정

```bash
# CLAUDE_PROJECT_DIR 환경변수가 있으면 사용, 없으면 cwd
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
echo "orbit-init target: $PROJECT_ROOT"
```

인자(`$ARGUMENTS`)가 전달된 경우 해당 경로를 PROJECT_ROOT로 사용한다.

### Step 2: .orbit/ 디렉토리 생성

```bash
mkdir -p "$PROJECT_ROOT/.orbit"
```

이미 존재하면 기존 파일을 덮어쓰지 않는다(아래 Step 3~5에서 `-n` 플래그로 보호).

### Step 2.5: PLUGIN_ROOT 확정 및 가드 (필수)

템플릿 파일은 플러그인 번들 안에 있으므로 `CLAUDE_PLUGIN_ROOT`가 필요하다.
**커맨드 컨텍스트에서 `CLAUDE_PLUGIN_ROOT` 주입은 공식 보장이 없다**(훅과 달리).
미설정 시 경로가 빈 문자열이 되어 `cp`가 루트 절대경로로 무음 실패하므로,
**빈 값이면 여기서 명확히 중단**한다(무음 실패 방지).

```bash
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}"
if [ -z "$PLUGIN_ROOT" ] || [ ! -d "$PLUGIN_ROOT/templates" ]; then
  echo "[orbit-init] ERROR: 플러그인 템플릿 경로를 찾을 수 없습니다." >&2
  echo "  CLAUDE_PLUGIN_ROOT 가 설정되지 않았거나 templates/ 디렉터리가 없습니다." >&2
  echo "  (커맨드 컨텍스트에서는 CLAUDE_PLUGIN_ROOT 자동 주입이 보장되지 않습니다.)" >&2
  echo "" >&2
  echo "  해결: 플러그인 설치 경로를 찾아 수동 지정 후 /orbit-init 재실행." >&2
  echo "    예) export CLAUDE_PLUGIN_ROOT=<orbit 플러그인 설치 디렉터리>" >&2
  echo "        # 설치 경로는 보통 ~/.claude/plugins/.../orbit 하위입니다." >&2
  exit 1
fi
echo "orbit-init plugin root: $PLUGIN_ROOT"
```

이 가드를 통과하면 `$PLUGIN_ROOT/templates/`가 실제로 존재함이 보장된다.

### Step 3: roadmap.md 복사

```bash
cp -n "$PLUGIN_ROOT/templates/roadmap.template.md" \
      "$PROJECT_ROOT/.orbit/roadmap.md"
echo "created: .orbit/roadmap.md"
```

파일이 이미 있으면 `cp -n`이 건너뛴다. 기존 로드맵은 보존된다.

### Step 4: config 복사

```bash
cp -n "$PLUGIN_ROOT/templates/orbit-config.template" \
      "$PROJECT_ROOT/.orbit/config"
echo "created: .orbit/config"
```

### Step 5: quality-gate.sh 복사 및 실행 권한 부여

```bash
cp -n "$PLUGIN_ROOT/templates/quality-gate.template.sh" \
      "$PROJECT_ROOT/.orbit/quality-gate.sh"
chmod +x "$PROJECT_ROOT/.orbit/quality-gate.sh"
echo "created: .orbit/quality-gate.sh (no-op pass 기본값)"
```

기본 quality-gate.sh는 `exit 0`(no-op pass)이다.
프로젝트 빌드/린트 명령을 채워 커스터마이즈한다.

### Step 6: 동반 플러그인 확인 (Triple Crown 검증 필수 요건)

아래 플러그인들은 orbit Triple Crown 검증 프롱에 **필수**다 (v2.0.0, TIER-1).
미설치 시 해당 검증 프롱이 FAIL 처리된다. 이 단계는 경고만 출력하고 중단하지 않는다
(.orbit/ 스캐폴딩은 동반 플러그인과 무관하게 완료됨). 강제는 검증 프롱에서 이뤄진다.

```bash
MISSING=()

# superpowers — Triple Crown ③ 품질 프롱 필수 (superpowers:requesting-code-review)
if ! claude plugin list --json 2>/dev/null | python3 -c "import sys,json; pl=json.load(sys.stdin); exit(0 if any(p.get('name')=='superpowers' and p.get('enabled',False) for p in pl) else 1)" 2>/dev/null; then
  MISSING+=("superpowers")
fi

# gstack — Triple Crown ② 동작 프롱 필수 (/qa)
if ! claude plugin list --json 2>/dev/null | python3 -c "import sys,json; pl=json.load(sys.stdin); exit(0 if any(p.get('name')=='gstack' and p.get('enabled',False) for p in pl) else 1)" 2>/dev/null; then
  MISSING+=("gstack")
fi

# gsd — Triple Crown ① 완성도 프롱 필수 (/gsd-verify-work)
if ! claude plugin list --json 2>/dev/null | python3 -c "import sys,json; pl=json.load(sys.stdin); exit(0 if any(p.get('name')=='gsd' and p.get('enabled',False) for p in pl) else 1)" 2>/dev/null; then
  MISSING+=("gsd")
fi

if [ ${#MISSING[@]} -gt 0 ]; then
  echo ""
  echo "[orbit-init] ⚠ Triple Crown 검증에 필수인 동반 플러그인이 미설치/비활성입니다: ${MISSING[*]}"
  echo "  아래 플러그인이 없으면 해당 검증 프롱이 FAIL 처리됩니다:"
  for p in "${MISSING[@]}"; do
    case "$p" in
      superpowers) echo "  - superpowers (③ 품질 프롱): /plugin install superpowers@claude-plugins-official" ;;
      gstack)      echo "  - gstack (② 동작 프롱): git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack && cd ~/.claude/skills/gstack && ./setup" ;;
      gsd)         echo "  - gsd (① 완성도 프롱): /gsd-help 실행 또는 /plugin install gsd" ;;
    esac
  done
  echo ""
  echo "  CI/헤드리스 환경에서 검증 프롱 훅 체크를 건너뛰려면:"
  echo "    export ORBIT_SKIP_COMPANION_CHECK=1"
  echo "  (단, reviewer 보고 계약은 이 환경변수의 영향을 받지 않습니다.)"
  echo ""
fi
```

`claude plugin list` 명령이 없는 환경에서도 위 스크립트는 에러 없이 실행된다
(python3 파이프라인이 실패하면 MISSING에 추가되어 경고가 출력된다).

### Step 7: 완료 안내 출력

```
.orbit/ 초기화 완료:

  .orbit/roadmap.md       ← 백로그·마일스톤 원장 (채워 넣기)
  .orbit/config           ← tmux 세션명 등 설정
  .orbit/quality-gate.sh  ← 품질 게이트 (기본 no-op, 프로젝트 맞게 수정)

다음 단계:
  1. .orbit/roadmap.md 를 열어 첫 번째 작업을 백로그에 추가한다.
  2. /orbit-cycle 로 작업 1건 생명주기를 시작한다.
  3. (선택) .orbit/config 에서 ORBIT_TMUX_SESSION 을 수정한다.
  4. (선택) .orbit/quality-gate.sh 에 프로젝트 빌드/린트 명령을 채운다.
  5. (선택) tmux 팀 환경(리드 + 뷰어 2팬)을 쓰려면:
       bash "${CLAUDE_PLUGIN_ROOT}/scripts/setup-orbit.sh"
```

## 주의사항

- `cp -n` 사용으로 기존 `.orbit/` 파일은 절대 덮어쓰지 않는다.
- 이 커맨드는 플러그인 번들의 `templates/`를 복사하므로 `CLAUDE_PLUGIN_ROOT`가 필요하다.
  커맨드 컨텍스트에서는 이 변수의 자동 주입이 보장되지 않는다(훅과 달리). 미설정이면
  Step 2.5 가드가 명확한 에러로 중단시킨다 — 안내대로 `export CLAUDE_PLUGIN_ROOT=<경로>` 후 재실행한다.
- `.orbit/` 하위 파일은 `.gitignore`에 추가하거나 커밋해도 무방하다(팀 공유 가능).
