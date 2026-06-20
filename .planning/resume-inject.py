#!/usr/bin/env python3
"""UserPromptSubmit 훅 → pending-resume.json 감지 → 프롬프트 앞에 경고 주입"""
import sys, json, os, time

PENDING = os.path.join(os.environ.get('CLAUDE_PROJECT_DIR', os.getcwd()), '.planning', 'pending-resume.json')

if not os.path.exists(PENDING):
    sys.exit(0)

try:
    data = json.load(open(PENDING))
    reset_epoch = data.get('reset_epoch', 0)
except Exception:
    os.remove(PENDING)
    sys.exit(0)

inp = json.loads(sys.stdin.read())
orig = inp.get('prompt', '')
now = time.time()

if reset_epoch > now:
    delay = int(reset_epoch - now) + 120
    inp['prompt'] = (
        f'[USAGE-WARNING] 사용량 한계 임박. '
        f'ScheduleWakeup(delaySeconds={delay}, '
        f'prompt=".planning/roadmap.md 현재 진행 중 이어서 진행") 즉시 호출.\n\n'
        + orig
    )
else:
    os.remove(PENDING)
    inp['prompt'] = (
        '[AUTO-RESUME] 사용량 리셋됨. .planning/roadmap.md 현재 진행 중 이어서 진행.\n\n'
        + orig
    )

print(json.dumps(inp))
