# dsh-pojia-mode 仓库元数据设置
import json, urllib.request

TOKEN_FILE = r"E:\DSH-Workspace\GitHub代管\token.txt"
REPO = "z91772524-ai/dsh-pojia-mode"

tok = [l.strip() for l in open(TOKEN_FILE, encoding="utf-8").read().splitlines()
       if l.strip() and not l.startswith("#")][0]

HEADERS = {
    "Authorization": "Bearer " + tok,
    "User-Agent": "dsh-pojia-mode",
    "Accept": "application/vnd.github+json",
    "Content-Type": "application/json",
}


def api(method, url, payload=None):
    data = json.dumps(payload, ensure_ascii=True).encode("utf-8") if payload is not None else None
    req = urllib.request.Request(url, data=data, method=method, headers=HEADERS)
    return json.loads(urllib.request.urlopen(req).read().decode("utf-8"))


# 1) 描述
meta = api("PATCH", f"https://api.github.com/repos/{REPO}", {
    "description": "双击一个文件，给 DeepSeek Harness 加一个「破甲模式」Agent Preset —— 零侵入、零依赖、双击无黑框，不改 DSH 一字节代码，升级不丢。",
})
print("  [OK] 描述:", meta["description"])

# 2) Topics（ASCII，有搜索量的词；对齐 pojia-next 风格）
topics = api("PUT", f"https://api.github.com/repos/{REPO}/topics", {
    "names": [
        "deepseek-harness", "dsh", "agent-preset", "cordis",
        "unlock", "pojia", "preset", "persona",
        "one-click", "powershell", "windows", "ai-agent",
        "prompt-injection", "self-check", "no-dependencies", "installer",
    ]
})
print("  [OK] Topics:", ", ".join(topics["names"]))

# 3) 确认最终状态
final = api("GET", f"https://api.github.com/repos/{REPO}")
print()
print("  full_name   :", final["full_name"])
print("  private     :", final["private"])
print("  description :", final["description"])
print("  default     :", final["default_branch"])
