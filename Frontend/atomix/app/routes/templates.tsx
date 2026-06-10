import { useEffect, useState } from "react";
import { useNavigate } from "react-router";
import { AppModal } from "~/components/app-modal";
import { SvgIcon } from "~/components/svg-icon";
import {
  getTemplates,
  deleteTemplate,
  createTemplate,
  subscribeTemplates,
  type Template,
} from "../store/templates-store";

function formatArea(area: string | null): string {
  return area ?? "Не присвоен";
}

export default function TemplatesPage() {
  const navigate = useNavigate();
  const [templates, setTemplates] = useState<Template[]>(getTemplates);
  const [search, setSearch] = useState("");
  const [templateToDelete, setTemplateToDelete] = useState<Template | null>(
    null,
  );

  useEffect(() => {
    const unsubscribe = subscribeTemplates(() => setTemplates(getTemplates()));
    return () => {
      unsubscribe();
    };
  }, []);

  const filtered = templates.filter((template) => {
    const query = search.toLowerCase();
    return (
      template.date.includes(query) ||
      formatArea(template.area).toLowerCase().includes(query)
    );
  });

  function handleCreate() {
    const id = createTemplate();
    navigate(`/templates/editor?id=${id}&isNew=1`);
  }

  function handleEdit(id: number) {
    navigate(`/templates/editor?id=${id}`);
  }

  function handleDelete(template: Template) {
    setTemplateToDelete(template);
  }

  function confirmDelete() {
    if (!templateToDelete) return;

    deleteTemplate(templateToDelete.id);
    setTemplateToDelete(null);
  }

  return (
    <div className="ui-page tpl-list">
      <div className="ui-toolbar tpl-list__toolbar">
        <button
          className="btn btn--primary"
          type="button"
          onClick={handleCreate}
        >
          <SvgIcon name="add" />
          Создать новый шаблон
        </button>

        <div className="ui-search">
          <span className="ui-search__icon">
            <SvgIcon name="search" />
          </span>
          <input
            className="ui-search__input"
            placeholder="Поиск..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
      </div>

      <div className="ui-card tpl-list__card">
        <div className="ui-card__header">
          <h2 className="ui-card__title">Список шаблонов</h2>
        </div>

        <div className="ui-table-wrap">
          <table className="ui-table">
            <thead>
              <tr>
                <th>№</th>
                <th>Дата создания</th>
                <th>Участок</th>
                <th>Действия</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((template, idx) => (
                <tr key={template.id}>
                  <td>{idx + 1}</td>
                  <td>{template.date}</td>
                  <td>{formatArea(template.area)}</td>
                  <td>
                    <div className="tpl-table__actions">
                      <button
                        type="button"
                        className="icon-btn icon-btn--edit"
                        onClick={() => handleEdit(template.id)}
                        title="Редактировать"
                      >
                        <SvgIcon name="edit" />
                      </button>
                      <button
                        type="button"
                        className="icon-btn icon-btn--delete"
                        onClick={() => handleDelete(template)}
                        title="Удалить"
                      >
                        <SvgIcon name="delete" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
              {filtered.length === 0 && (
                <tr>
                  <td colSpan={4} className="ui-empty">
                    Шаблоны не найдены
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      <AppModal
        open={Boolean(templateToDelete)}
        title="Удалить шаблон?"
        description={
          templateToDelete
            ? `Шаблон от ${templateToDelete.date} будет удалён без возможности восстановления.`
            : undefined
        }
        onClose={() => setTemplateToDelete(null)}
        actions={
          <>
            <button
              type="button"
              className="btn btn--ghost"
              onClick={() => setTemplateToDelete(null)}
            >
              Отмена
            </button>
            <button
              type="button"
              className="btn btn--danger"
              onClick={confirmDelete}
            >
              Удалить
            </button>
          </>
        }
      />
    </div>
  );
}
