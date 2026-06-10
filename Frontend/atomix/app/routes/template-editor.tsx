import { useEffect, useState } from "react";
import { useNavigate, useSearchParams } from "react-router";
import { AppModal } from "~/components/app-modal";
import { SvgIcon } from "~/components/svg-icon";
import {
  deleteTemplate,
  getTemplate,
  saveTemplate,
  nextItemId,
  type TemplateSection,
  type TemplateItem,
} from "../store/templates-store";

const AREAS = ["Не присвоен", "№1", "№2", "№3", "№4", "№5", "№6", "№7", "№8"];
const UNITS = ["шт.", "м³", "м²", "м", "кг", "т", "л"];

type ToastState = {
  type: "success" | "info";
  message: string;
};

type PendingItemRemoval = {
  sectionId: number;
  itemId: number;
  itemName: string;
} | null;

export default function TemplateEditorPage() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const id = Number(searchParams.get("id"));
  const isNew = searchParams.get("isNew") === "1";

  const template = getTemplate(id);

  const [area, setArea] = useState<string>(template?.area ?? "");
  const [sections, setSections] = useState<TemplateSection[]>(
    template?.sections ?? [],
  );
  const [addForms, setAddForms] = useState<
    Record<number, { name: string; unit: string }>
  >({});
  const [isBackConfirmOpen, setIsBackConfirmOpen] = useState(false);
  const [isClearConfirmOpen, setIsClearConfirmOpen] = useState(false);
  const [pendingItemRemoval, setPendingItemRemoval] =
    useState<PendingItemRemoval>(null);
  const [toast, setToast] = useState<ToastState | null>(null);
  const [wasSaved, setWasSaved] = useState(false);

  useEffect(() => {
    if (!template) navigate("/templates");
  }, [template, navigate]);

  useEffect(() => {
    if (!toast) return undefined;

    const timeout = window.setTimeout(() => setToast(null), 2500);
    return () => window.clearTimeout(timeout);
  }, [toast]);

  if (!template) return null;

  function removeItem(sectionId: number, itemId: number) {
    setSections((prev) =>
      prev.map((section) =>
        section.id === sectionId
          ? {
              ...section,
              items: section.items.filter((item) => item.id !== itemId),
            }
          : section,
      ),
    );
  }

  function requestItemRemoval(sectionId: number, item: TemplateItem) {
    setPendingItemRemoval({
      sectionId,
      itemId: item.id,
      itemName: item.name,
    });
  }

  function confirmItemRemoval() {
    if (!pendingItemRemoval) return;

    removeItem(pendingItemRemoval.sectionId, pendingItemRemoval.itemId);
    setPendingItemRemoval(null);
  }

  function addItem(sectionId: number) {
    const form = addForms[sectionId];
    if (!form?.name.trim()) return;

    const newItem: TemplateItem = {
      id: nextItemId(),
      name: form.name.trim(),
      unit: form.unit.trim(),
    };

    setSections((prev) =>
      prev.map((section) =>
        section.id === sectionId
          ? { ...section, items: [...section.items, newItem] }
          : section,
      ),
    );

    setAddForms((prev) => ({
      ...prev,
      [sectionId]: { name: "", unit: "" },
    }));
  }

  function updateAddForm(
    sectionId: number,
    field: "name" | "unit",
    value: string,
  ) {
    setAddForms((prev) => ({
      ...prev,
      [sectionId]: {
        ...prev[sectionId],
        name: prev[sectionId]?.name ?? "",
        unit: prev[sectionId]?.unit ?? "",
        [field]: value,
      },
    }));
  }

  function addSection() {
    const newId = Date.now();
    setSections((prev) => [
      ...prev,
      { id: newId, title: `Здание ${prev.length + 1}`, items: [] },
    ]);
  }

  function saveCurrentTemplate() {
    saveTemplate(id, area || null, sections);
  }

  function handleSave() {
    saveCurrentTemplate();
    setWasSaved(true);
    setToast({ type: "success", message: "Шаблон успешно сохранён" });
  }

  function handleBackClick() {
    setIsBackConfirmOpen(true);
  }

  function handleBackSave() {
    saveCurrentTemplate();
    setWasSaved(true);
    setIsBackConfirmOpen(false);
    navigate("/templates");
  }

  function handleBackDiscard() {
    if (isNew && !wasSaved) {
      deleteTemplate(id);
    }

    setIsBackConfirmOpen(false);
    navigate("/templates");
  }

  function handleClear() {
    setIsClearConfirmOpen(true);
  }

  function confirmClear() {
    setSections([]);
    setArea("");
    setAddForms({});
    setIsClearConfirmOpen(false);
  }

  return (
    <div className="tpl-editor">
      <div className="tpl-editor__toolbar">
        <button
          className="btn btn--ghost btn--icon tpl-editor__back"
          onClick={handleBackClick}
          title="Назад"
        >
          <SvgIcon name="back" />
        </button>

        <div className="ui-select-wrap tpl-editor__area-wrap">
          <select
            className="ui-select tpl-editor__area-select"
            value={area}
            onChange={(e) => setArea(e.target.value)}
          >
            <option value="">Выбрать назначение</option>
            {AREAS.map((item) => (
              <option key={item} value={item}>
                {item}
              </option>
            ))}
          </select>
          <SvgIcon name="chevron-down" className="ui-select-wrap__icon" />
        </div>

        <div className="tpl-editor__toolbar-actions">
          <button className="btn btn--success" onClick={handleSave}>
            <SvgIcon name="save" />
            Сохранить
          </button>
          <button className="btn btn--danger" onClick={handleClear}>
            <SvgIcon name="delete" />
            Очистить
          </button>
        </div>
      </div>

      <div className="tpl-editor__divider" />

      <div className="tpl-editor__body">
        <div className="tpl-editor__col-header">
          Наименование отчётной позиции
        </div>

        {sections.map((section) => {
          const form = addForms[section.id] ?? { name: "", unit: "" };

          return (
            <div key={section.id} className="tpl-section">
              <div className="tpl-section__title">{section.title}</div>

              {section.items.map((item, idx) => (
                <div key={item.id} className="tpl-item">
                  <span className="tpl-item__num">{idx + 1}</span>
                  <span className="tpl-item__name">{item.name}</span>
                  <button
                    className="icon-btn icon-btn--delete tpl-item__remove"
                    onClick={() => requestItemRemoval(section.id, item)}
                    title="Удалить позицию"
                  >
                    <SvgIcon name="delete" />
                  </button>
                </div>
              ))}

              <div className="tpl-add">
                <div className="tpl-add__title">Добавить новую позицию</div>

                <div className="tpl-add__form">
                  <select className="ui-select tpl-add__type">
                    <option>ввести вручную</option>
                  </select>
                  <input
                    className="ui-input tpl-add__name"
                    placeholder="Название позиции"
                    value={form.name}
                    onChange={(e) =>
                      updateAddForm(section.id, "name", e.target.value)
                    }
                    onKeyDown={(e) => e.key === "Enter" && addItem(section.id)}
                  />
                  <div className="ui-select-wrap tpl-add__unit-wrap">
                    <select
                      className="ui-select tpl-add__unit"
                      value={form.unit}
                      onChange={(e) =>
                        updateAddForm(section.id, "unit", e.target.value)
                      }
                    >
                      <option value="">Ед. изм.</option>
                      {UNITS.map((unit) => (
                        <option key={unit} value={unit}>
                          {unit}
                        </option>
                      ))}
                    </select>
                    <SvgIcon name="chevron-down" className="ui-select-wrap__icon" />
                  </div>
                  <button
                    className="btn btn--success tpl-add__btn"
                    onClick={() => addItem(section.id)}
                  >
                    Добавить
                  </button>
                </div>
              </div>
            </div>
          );
        })}

        <button className="tpl-editor__add-section" onClick={addSection}>
          <SvgIcon name="add" />
          Добавить здание
        </button>
      </div>

      <AppModal
        open={isBackConfirmOpen}
        title="Хотите сохранить шаблон?"
        description="Перед выходом можно сохранить внесённые изменения."
        onClose={() => setIsBackConfirmOpen(false)}
        actions={
          <>
            <button
              type="button"
              className="btn btn--ghost"
              onClick={handleBackDiscard}
            >
              Нет
            </button>
            <button
              type="button"
              className="btn btn--success"
              onClick={handleBackSave}
            >
              Да
            </button>
          </>
        }
      />

      <AppModal
        open={isClearConfirmOpen}
        title="Очистить шаблон?"
        description="Все здания и отчётные позиции в текущем шаблоне будут удалены."
        onClose={() => setIsClearConfirmOpen(false)}
        actions={
          <>
            <button
              type="button"
              className="btn btn--ghost"
              onClick={() => setIsClearConfirmOpen(false)}
            >
              Отмена
            </button>
            <button
              type="button"
              className="btn btn--danger"
              onClick={confirmClear}
            >
              Очистить
            </button>
          </>
        }
      />

      <AppModal
        open={Boolean(pendingItemRemoval)}
        title="Удалить позицию?"
        description={
          pendingItemRemoval
            ? `Позиция «${pendingItemRemoval.itemName}» будет удалена из шаблона.`
            : undefined
        }
        onClose={() => setPendingItemRemoval(null)}
        actions={
          <>
            <button
              type="button"
              className="btn btn--ghost"
              onClick={() => setPendingItemRemoval(null)}
            >
              Отмена
            </button>
            <button
              type="button"
              className="btn btn--danger"
              onClick={confirmItemRemoval}
            >
              Удалить
            </button>
          </>
        }
      />

      {toast ? (
        <div className={`toast toast--${toast.type}`}>{toast.message}</div>
      ) : null}
    </div>
  );
}
