#!/usr/bin/env python3
"""从所有 .gd 源码中提取用到的字符，对字体做子集化。"""
import os, re, subprocess, glob

ROOT = os.path.join(os.path.dirname(__file__), "..")
FONT_DIR = os.path.join(ROOT, "assets", "fonts")

def collect_chars():
    chars = set()
    for path in glob.glob(os.path.join(ROOT, "scripts", "**", "*.gd"), recursive=True):
        with open(path, encoding="utf-8") as f:
            text = f.read()
        chars.update(re.findall(r"[\u0020-\u007e\u4e00-\u9fff\u3000-\u303f\uff00-\uffef\u2192\u25b8\u2318]", text))
    # 常用标点与数字补充
    chars.update("0123456789.:-+%ms/")
    return "".join(sorted(chars))

def subset(src, dst, text):
    subprocess.run(["pyftsubset", src, f"--text={text}", f"--output-file={dst}",
                    "--layout-features=*", "--glyph-names", "--no-hinting"],
                   check=True)
    print("wrote", dst, os.path.getsize(dst))

if __name__ == "__main__":
    text = collect_chars()
    print("unique chars:", len(text))
    subset(os.path.join(FONT_DIR, "NotoSansSC-Regular.otf"), os.path.join(FONT_DIR, "main.ttf"), text)
    subset(os.path.join(FONT_DIR, "NotoSansSC-Bold.otf"), os.path.join(FONT_DIR, "bold.ttf"), text)
