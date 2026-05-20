export type TemplateItem = {
  id: number;
  name: string;
  unit: string;
};

export type TemplateSection = {
  id: number;
  title: string;
  items: TemplateItem[];
};

export type Template = {
  id: number;
  date: string;
  area: string | null;
  sections: TemplateSection[];
};

let _nextId = 5;
let _nextItemId = 100;

let _templates: Template[] = [
  {
    id: 1,
    date: "22.12.2025",
    area: null,
    sections: [
      {
        id: 1,
        title: "Здание 1",
        items: [
          { id: 1, name: "Количество принятых и переработанных методом аммиачного осаждения растворов за смену, м³", unit: "м³" },
          { id: 2, name: "Количество прокалённой пульпы за смену, м³", unit: "м³" },
        ],
      },
    ],
  },
  {
    id: 2,
    date: "11.01.2026",
    area: "№4",
    sections: [
      {
        id: 1,
        title: "Здание 1",
        items: [
          { id: 3, name: "Количество принятых и переработанных методом известкования растворов за смену, м³", unit: "м³" },
          { id: 4, name: "Отфильтровано пульпы за смену, м³", unit: "м³" },
          { id: 5, name: "Получено контейнеров за смену, шт.", unit: "шт." },
          { id: 6, name: "Количество принятых и переработанных методом известкования растворов, м³", unit: "м³" },
        ],
      },
    ],
  },
  {
    id: 3,
    date: "17.01.2026",
    area: "№7",
    sections: [],
  },
  {
    id: 4,
    date: "20.01.2026",
    area: "№2",
    sections: [],
  },
];

// Listeners for re-render triggering
const listeners = new Set<() => void>();

export function subscribeTemplates(fn: () => void) {
  listeners.add(fn);
  return () => listeners.delete(fn);
}

function notify() {
  listeners.forEach((fn) => fn());
}

export function getTemplates(): Template[] {
  return _templates;
}

export function getTemplate(id: number): Template | undefined {
  return _templates.find((t) => t.id === id);
}

export function deleteTemplate(id: number) {
  _templates = _templates.filter((t) => t.id !== id);
  notify();
}

export function createTemplate(): number {
  const today = new Date();
  const date = today.toLocaleDateString("ru-RU", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
  });
  const id = _nextId++;
  _templates = [
    ..._templates,
    { id, date, area: null, sections: [] },
  ];
  notify();
  return id;
}

export function saveTemplate(id: number, area: string | null, sections: TemplateSection[]) {
  _templates = _templates.map((t) =>
    t.id === id ? { ...t, area, sections } : t
  );
  notify();
}

export function nextItemId(): number {
  return _nextItemId++;
}
