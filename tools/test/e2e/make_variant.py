# -*- coding: utf-8 -*-
"""
把任意 commit 的 bin/lib/*.ahk + 生成物入口脚本导出成一份**可独立运行**的变体,
用于 E2E 二分。不切换工作区、不修改 bin/lib、不改 data/config.json。

布局:
  _e2e_variants/<tag>/bin/MyKeymap.ahk      <- 该 commit 的生成物(若被 gitignore 则用当前工作区副本)
  _e2e_variants/<tag>/bin/lib/*.ahk         <- 该 commit 的 lib
  _e2e_variants/<tag>/data/{config.json,custom_functions.ahk}  <- 只读副本

为什么这样能跑: 生成物首行附近有 SetWorkingDir("../")，cwd=bin 时工作目录变为
<tag>/，其中的 data/ 就是副本目录，所以 ../data/config.json 之类的引用不会碰到真件。

用法:
    python tools/e2e/make_variant.py <commit> [--entry-from-worktree]
"""
import os
import shutil
import subprocess
import sys

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
VARIANTS = os.path.join(ROOT, "_e2e_variants")

LIB_FILES = ("Actions.ahk", "Functions.ahk", "KeymapManager.ahk",
             "InputTipWindow.ahk", "Utils.ahk", "Midi.ahk", "translation.ahk")


def sh(*args):
    # 必须显式指定 UTF-8: 仓库里的 .ahk 是 UTF-8(带/不带 BOM),
    # 默认 text=True 会用 GBK 解码 -> UnicodeDecodeError -> 静默回落到 HEAD,
    # 那样所有变体都会变成 HEAD 的代码, 二分失效(实测踩过)。
    return subprocess.run(args, cwd=ROOT, capture_output=True,
                          encoding="utf-8", errors="replace")


def git_show(commit, path):
    p = sh("git", "show", "%s:%s" % (commit, path))
    return p.stdout if p.returncode == 0 else None


def main():
    commit = sys.argv[1]
    tag = sys.argv[2] if len(sys.argv) > 2 else commit
    dest = os.path.join(VARIANTS, tag)
    if os.path.isdir(dest):
        shutil.rmtree(dest)
    os.makedirs(os.path.join(dest, "bin", "lib"), exist_ok=True)
    os.makedirs(os.path.join(dest, "data"), exist_ok=True)

    # 1) lib: 优先用该 commit 的内容; 该 commit 不存在的文件回落到 HEAD
    got, fallback = [], []
    for name in LIB_FILES:
        content = git_show(commit, "bin/lib/" + name)
        if content is None:
            src = os.path.join(ROOT, "bin", "lib", name)
            if os.path.exists(src):
                shutil.copy2(src, os.path.join(dest, "bin", "lib", name))
                fallback.append(name)
            continue
        with open(os.path.join(dest, "bin", "lib", name), "w",
                  encoding="utf-8", newline="") as f:
            f.write(content)
        got.append(name)

    # 2) 入口脚本: 生成物被 gitignore, 所以一律用当前工作区那份(内容由当前 config.json 决定)
    entry_src = os.path.join(ROOT, "bin", "MyKeymap.ahk")
    entry_dst = os.path.join(dest, "bin", "MyKeymap.ahk")
    shutil.copy2(entry_src, entry_dst)

    # 3) data 只读副本(绝不修改原件)
    for name in ("config.json", "custom_functions.ahk"):
        src = os.path.join(ROOT, "data", name)
        if os.path.exists(src):
            shutil.copy2(src, os.path.join(dest, "data", name))

    print("variant: %s" % dest)
    print("  lib from commit : %s" % ", ".join(got))
    print("  lib fallback HEAD: %s" % (", ".join(fallback) or "(none)"))
    print("  entry: 工作区当前生成物副本")
    print("  data : 只读副本(原件 SHA 未变)")

    # 校验: 入口的实际 #Include 是否都能解析
    missing = []
    text = open(entry_dst, encoding="utf-8-sig", errors="replace").read()
    for line in text.splitlines():
        s = line.strip()
        if s.lower().startswith("#include"):
            rel = s.split(None, 1)[1].strip()
            rel = rel.replace("${A_ScriptDir}", "")
            if rel.startswith("../data/"):
                target = os.path.join(dest, rel[3:])
            else:
                target = os.path.join(dest, "bin", rel)
            if not os.path.exists(target):
                missing.append(rel)
    print("  include 缺失: %s" % (missing or "无"))
    print("ENTRY=%s" % entry_dst)


if __name__ == "__main__":
    main()
