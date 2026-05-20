import json

with open("описание_проекта 06.05.26.json", "r", encoding="utf-8") as f:
    data = json.load(f)

with open("описание_проекта 06.05.26.min.json", "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, separators=(",", ":"))