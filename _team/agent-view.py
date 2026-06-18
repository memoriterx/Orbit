#!/usr/bin/env python3
"""에이전트 transcript(JSONL)를 사람이 보기 좋은 실시간 화면으로 포맷.
사용: agent-view.py <에이전트라벨> --file <transcript.jsonl> --follow
"""
import sys, json, time, argparse

C = {
    "cyan":   "\033[36m",
    "green":  "\033[32m",
    "yellow": "\033[33m",
    "gray":   "\033[90m",
    "red":    "\033[31m",
    "bold":   "\033[1m",
    "reset":  "\033[0m",
    "mag":    "\033[35m",
    "blue":   "\033[34m",
    "white":  "\033[97m",
}

def truncate(s, n=120):
    s = str(s)
    return s if len(s) <= n else s[:n] + "…"

def fmt_diff(old, new):
    lines = []
    for line in str(old).splitlines():
        lines.append(f"{C['red']}- {line}{C['reset']}")
    for line in str(new).splitlines():
        lines.append(f"{C['green']}+ {line}{C['reset']}")
    return "\n".join(lines)

def fmt_tool_use(name, inp):
    lines = []
    header_color = C["cyan"]

    if name == "Edit":
        path = inp.get("file_path", "?")
        lines.append(f"{header_color}{C['bold']}✏️  Edit → {path}{C['reset']}")
        old = inp.get("old_string", "")
        new = inp.get("new_string", "")
        lines.append(fmt_diff(old, new))

    elif name == "Write":
        path = inp.get("file_path", "?")
        lines.append(f"{header_color}{C['bold']}📝 Write → {path}{C['reset']}")
        content = inp.get("content", "")
        for line in str(content).splitlines():
            lines.append(f"{C['white']}{line}{C['reset']}")

    elif name == "Bash":
        cmd = inp.get("command", "?")
        desc = inp.get("description", "")
        label = f" ({desc})" if desc else ""
        lines.append(f"{header_color}{C['bold']}$ {cmd}{C['reset']}{C['gray']}{label}{C['reset']}")

    elif name == "Read":
        path = inp.get("file_path", "?")
        offset = inp.get("offset", "")
        limit = inp.get("limit", "")
        extra = f" L{offset}-{limit}" if offset else ""
        lines.append(f"{C['gray']}📖 Read → {path}{extra}{C['reset']}")

    elif name in ("Agent", "Task"):
        desc = inp.get("description", inp.get("title", ""))
        prompt_snippet = truncate(inp.get("prompt", ""), 200)
        lines.append(f"{C['mag']}{C['bold']}🤖 {name}: {desc}{C['reset']}")
        if prompt_snippet:
            lines.append(f"{C['gray']}{prompt_snippet}{C['reset']}")

    else:
        # 기타 도구: 첫 번째 인자 전체 출력
        hint = ""
        for k in ("command", "file_path", "path", "description", "query", "prompt", "pattern", "skill"):
            if k in inp:
                hint = f"{k}={inp[k]}"
                break
        lines.append(f"{C['cyan']}🔧 {name}  {C['gray']}{truncate(hint, 200)}{C['reset']}")

    return "\n".join(lines)

def fmt_tool_result(content):
    if isinstance(content, list):
        parts = []
        for c in content:
            if isinstance(c, dict) and c.get("type") == "text":
                parts.append(c.get("text", ""))
        text = "\n".join(parts)
    else:
        text = str(content)
    lines = []
    for line in text.splitlines()[:40]:  # 최대 40줄
        lines.append(f"{C['gray']}   │ {line}{C['reset']}")
    if len(text.splitlines()) > 40:
        lines.append(f"{C['gray']}   │ … (+{len(text.splitlines())-40} lines){C['reset']}")
    return "\n".join(lines) if lines else None

def fmt_line(raw, label):
    raw = raw.strip()
    if not raw:
        return None
    try:
        d = json.loads(raw)
    except Exception:
        return None
    t = d.get("type")
    msg = d.get("message")

    if t == "assistant" and isinstance(msg, dict):
        out = []
        for block in msg.get("content", []):
            if not isinstance(block, dict):
                continue
            bt = block.get("type")
            if bt == "text" and block.get("text", "").strip():
                txt = block["text"].strip()
                out.append(f"{C['green']}💬 {txt}{C['reset']}")
            elif bt == "tool_use":
                name = block.get("name", "?")
                inp = block.get("input", {})
                out.append(fmt_tool_use(name, inp))
        return "\n".join(out) if out else None

    if t == "tool" and isinstance(msg, dict):
        content = msg.get("content", "")
        result = fmt_tool_result(content)
        if result:
            return f"{C['gray']}   ↳ result:{C['reset']}\n{result}"
        return None

    return None

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("label")
    ap.add_argument("--file")
    ap.add_argument("--follow", action="store_true")
    a = ap.parse_args()
    hdr = f"{C['bold']}{C['mag']}━━ {a.label} ━━{C['reset']}"
    print(hdr); sys.stdout.flush()

    if a.file and a.follow:
        f = open(a.file, "r")
        f.seek(0)  # 처음부터 재생 후 follow
        while True:
            line = f.readline()
            if not line:
                time.sleep(0.4)
                continue
            s = fmt_line(line, a.label)
            if s:
                print(s)
                sys.stdout.flush()
    else:
        src = open(a.file) if a.file else sys.stdin
        for line in src:
            s = fmt_line(line, a.label)
            if s:
                print(s)
                sys.stdout.flush()

if __name__ == "__main__":
    main()
