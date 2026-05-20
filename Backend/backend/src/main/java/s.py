import os, json

def build_tree(path):
    result = []
    for item in sorted(os.listdir(path)):
        p = os.path.join(path, item)
        result.append({item: build_tree(p)} if os.path.isdir(p) else item)
    return result

root = os.path.dirname(os.path.abspath(__file__))
with open("structure.json", "w", encoding="utf-8") as f:
    json.dump(build_tree(root), f, ensure_ascii=False, separators=(",", ":"))