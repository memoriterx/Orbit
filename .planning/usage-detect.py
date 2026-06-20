#!/usr/bin/env python3
"""Notification 훅 → 사용량 경고 감지 → pending-resume.json 작성"""
import re, sys, json, os
from datetime import datetime, date, timedelta, time

PLANNING = os.path.join(os.environ.get('CLAUDE_PROJECT_DIR', os.getcwd()), '.planning')
os.makedirs(PLANNING, exist_ok=True)

raw = sys.stdin.read()
try:
    data = json.loads(raw)
    msg = data.get('message', '')
except Exception:
    msg = raw

with open(os.path.join(PLANNING, 'usage-detect.log'), 'a') as f:
    f.write(f'[{datetime.now():%F %T}] EVT=NOTIFICATION {raw.strip()}\n')

if not re.search(r'9[3-9]%|100%', msg, re.I):
    sys.exit(0)

m = re.search(r'(\d+):(\d+)\s*(AM|PM)?', msg, re.I)
if not m:
    sys.exit(0)

h, mn, mer = int(m.group(1)), int(m.group(2)), (m.group(3) or '').upper()
if mer == 'PM' and h != 12:
    h += 12
elif mer == 'AM' and h == 12:
    h = 0

reset_dt = datetime.combine(date.today(), time(h, mn))
now = datetime.now()
if reset_dt <= now:
    reset_dt += timedelta(days=1)

with open(os.path.join(PLANNING, 'pending-resume.json'), 'w') as f:
    json.dump({'reset_epoch': int(reset_dt.timestamp())}, f)
