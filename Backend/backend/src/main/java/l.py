import os
import json


def build_tree(root_path):
    tree = {}

    for item in sorted(os.listdir(root_path)):
        item_path = os.path.join(root_path, item)

        if os.path.isdir(item_path):
            tree[item] = build_tree(item_path)
        else:
            tree[item] = None  # файл

    return tree


def main():
    # Текущая директория (где лежит скрипт)
    root_dir = os.path.dirname(os.path.abspath(__file__))

    structure = build_tree(root_dir)

    with open("structure.json", "w", encoding="utf-8") as f:
        json.dump(structure, f, indent=4, ensure_ascii=False)

    print("JSON файл structure.json создан!")


if __name__ == "__main__":
    main()