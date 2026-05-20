import React, { useEffect, useMemo, useState } from "react";
import { AppModal } from "~/components/app-modal";
import { fetchReportDepartments, type EmployeeDepartmentOptionResponse } from "~/components/reportApi";
import { SvgIcon } from "~/components/svg-icon";
import { getStoredAuthUser } from "~/lib/auth";

type StructureNode = {
  id: string;
  parentId: string | null;
  name: string;
  shortName: string;
  hierarchyLevel: number;
  isActive: boolean;
  source: "api" | "local" | "fallback";
};

type CreateFormState = {
  type: "workshop" | "area";
  name: string;
  shortName: string;
  parentId: string;
};

const LOCAL_STRUCTURE_KEY = "enterprise-structure-local-departments";

const FALLBACK_STRUCTURE: StructureNode[] = [
  {
    id: "fallback-main-department-uralvagonzavod",
    parentId: null,
    name: "УралВагонЗавод",
    shortName: "УралВагонЗавод",
    hierarchyLevel: 0,
    isActive: true,
    source: "fallback"
  },
  {
    id: "fallback-workshop-2",
    parentId: "fallback-main-department-uralvagonzavod",
    name: "Цех №2",
    shortName: "Цех №2",
    hierarchyLevel: 1,
    isActive: true,
    source: "fallback"
  },
  {
    id: "fallback-area-7",
    parentId: "fallback-workshop-2",
    name: "Участок №7",
    shortName: "Участок №7",
    hierarchyLevel: 2,
    isActive: true,
    source: "fallback"
  }
];

function readLocalDepartments(): StructureNode[] {
  if (typeof window === "undefined") return [];

  try {
    const raw = window.localStorage.getItem(LOCAL_STRUCTURE_KEY);
    if (!raw) return [];

    const parsed = JSON.parse(raw) as Partial<StructureNode>[];
    if (!Array.isArray(parsed)) return [];

    return parsed
      .map((department) => ({
        id: String(department.id ?? "").trim(),
        parentId: department.parentId ? String(department.parentId).trim() : null,
        name: String(department.name ?? "").trim(),
        shortName: String(department.shortName ?? department.name ?? "").trim(),
        hierarchyLevel: Number.isFinite(Number(department.hierarchyLevel)) ? Number(department.hierarchyLevel) : 0,
        isActive: department.isActive !== false,
        source: "local" as const
      }))
      .filter((department) => department.id && department.name);
  } catch {
    return [];
  }
}

function saveLocalDepartments(departments: StructureNode[]): void {
  if (typeof window === "undefined") return;
  window.localStorage.setItem(LOCAL_STRUCTURE_KEY, JSON.stringify(departments));
}

function normalizeApiDepartments(departments: EmployeeDepartmentOptionResponse[]): StructureNode[] {
  const normalized = departments
    .map((department) => ({
      id: String(department.departmentId ?? "").trim(),
      parentId: department.parentDepartmentId ? String(department.parentDepartmentId).trim() : null,
      name: String(department.name ?? "").trim(),
      shortName: String(department.shortName ?? department.name ?? "").trim(),
      hierarchyLevel: Number.isFinite(Number(department.hierarchyLevel)) ? Number(department.hierarchyLevel) : Number.NaN,
      isActive: department.isActive !== false,
      source: "api" as const
    }))
    .filter((department) => department.id && department.name && department.isActive);

  const byId = new Map(normalized.map((department) => [department.id, department]));
  const levelCache = new Map<string, number>();

  const resolveLevel = (department: StructureNode, stack = new Set<string>()): number => {
    if (Number.isFinite(department.hierarchyLevel)) return department.hierarchyLevel;
    if (levelCache.has(department.id)) return levelCache.get(department.id) ?? 0;
    if (!department.parentId || stack.has(department.id)) return 0;

    const parent = byId.get(department.parentId);
    if (!parent) return 0;

    stack.add(department.id);
    const resolvedLevel = resolveLevel(parent, stack) + 1;
    stack.delete(department.id);
    levelCache.set(department.id, resolvedLevel);
    return resolvedLevel;
  };

  return normalized.map((department) => ({
    ...department,
    hierarchyLevel: resolveLevel(department)
  }));
}

function getNodeTypeLabel(level: number): string {
  if (level <= 0) return "Главный департамент";
  if (level === 1) return "Цех";
  return "Участок";
}

function getNodeBadgeClass(level: number): string {
  if (level <= 0) return "enterprise-structure-badge--root";
  if (level === 1) return "enterprise-structure-badge--workshop";
  return "enterprise-structure-badge--area";
}

function getDisplayName(node: StructureNode): string {
  return node.shortName || node.name || "Без названия";
}

function createLocalId(): string {
  if (typeof crypto !== "undefined" && "randomUUID" in crypto) {
    return `local-${crypto.randomUUID()}`;
  }

  return `local-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
}

function sortNodes(nodes: StructureNode[]): StructureNode[] {
  return [...nodes].sort((a, b) => {
    const levelCompare = a.hierarchyLevel - b.hierarchyLevel;
    if (levelCompare !== 0) return levelCompare;
    return getDisplayName(a).localeCompare(getDisplayName(b), "ru");
  });
}

export default function EnterpriseStructurePage(): React.ReactElement {
  const authUser = useMemo(() => getStoredAuthUser(), []);

  const [apiDepartments, setApiDepartments] = useState<StructureNode[]>([]);
  const [localDepartments, setLocalDepartments] = useState<StructureNode[]>([]);
  const [expandedIds, setExpandedIds] = useState<Set<string>>(new Set());
  const [searchValue, setSearchValue] = useState("");
  const [isLoading, setIsLoading] = useState(true);
  const [errorMessage, setErrorMessage] = useState("");
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  const [createForm, setCreateForm] = useState<CreateFormState>({
    type: "workshop",
    name: "",
    shortName: "",
    parentId: ""
  });

  useEffect(() => {
    setLocalDepartments(readLocalDepartments());
  }, []);

  useEffect(() => {
    let isMounted = true;

    const loadDepartments = async () => {
      if (!authUser?.userId) {
        setErrorMessage("Не удалось определить текущего пользователя. Выполните вход заново.");
        setApiDepartments([]);
        setIsLoading(false);
        return;
      }

      try {
        setIsLoading(true);
        setErrorMessage("");

        const context = await fetchReportDepartments(authUser.userId);
        const normalizedDepartments = normalizeApiDepartments(context.departments ?? []);

        if (!isMounted) return;
        setApiDepartments(normalizedDepartments);
      } catch (error) {
        if (!isMounted) return;
        setApiDepartments([]);
        setErrorMessage(error instanceof Error ? error.message : "Не удалось загрузить структуру предприятия.");
      } finally {
        if (isMounted) {
          setIsLoading(false);
        }
      }
    };

    void loadDepartments();

    return () => {
      isMounted = false;
    };
  }, [authUser?.userId]);

  const baseDepartments = apiDepartments.length > 0 ? apiDepartments : FALLBACK_STRUCTURE;

  const departments = useMemo(() => {
    const merged = new Map<string, StructureNode>();

    [...baseDepartments, ...localDepartments].forEach((department) => {
      merged.set(department.id, department);
    });

    return sortNodes([...merged.values()].filter((department) => department.isActive));
  }, [baseDepartments, localDepartments]);

  const departmentIdsSignature = useMemo(() => departments.map((department) => department.id).join("|"), [departments]);

  useEffect(() => {
    setExpandedIds(new Set(departments.map((department) => department.id)));
  }, [departmentIdsSignature]);

  const departmentById = useMemo(() => {
    return new Map(departments.map((department) => [department.id, department]));
  }, [departments]);

  const childMap = useMemo(() => {
    const map = new Map<string, StructureNode[]>();

    departments.forEach((department) => {
      if (!department.parentId) return;
      const children = map.get(department.parentId) ?? [];
      children.push(department);
      map.set(department.parentId, sortNodes(children));
    });

    return map;
  }, [departments]);

  const rootNodes = useMemo(() => {
    return sortNodes(
      departments.filter((department) => !department.parentId || !departmentById.has(department.parentId))
    );
  }, [departmentById, departments]);

  const workshopOptions = useMemo(() => {
    return departments.filter((department) => department.hierarchyLevel === 1);
  }, [departments]);

  const rootOptions = useMemo(() => {
    return departments.filter((department) => department.hierarchyLevel <= 0 || !department.parentId);
  }, [departments]);

  const parentOptions = createForm.type === "workshop" ? rootOptions : workshopOptions;
  const parentOptionsSignature = parentOptions.map((department) => department.id).join("|");

  useEffect(() => {
    const firstParentId = parentOptions[0]?.id ?? "";

    setCreateForm((current) => {
      if (current.parentId && parentOptions.some((department) => department.id === current.parentId)) {
        return current;
      }

      return { ...current, parentId: firstParentId };
    });
  }, [createForm.type, parentOptionsSignature]);

  const normalizedSearch = searchValue.trim().toLowerCase();

  const visibleNodeIds = useMemo(() => {
    if (!normalizedSearch) return new Set(departments.map((department) => department.id));

    const visible = new Set<string>();

    departments.forEach((department) => {
      const searchTarget = `${department.name} ${department.shortName} ${getNodeTypeLabel(department.hierarchyLevel)}`.toLowerCase();
      if (!searchTarget.includes(normalizedSearch)) return;

      const addDescendants = (currentNode: StructureNode): void => {
        visible.add(currentNode.id);
        (childMap.get(currentNode.id) ?? []).forEach((child) => addDescendants(child));
      };

      addDescendants(department);

      let current: StructureNode | undefined = department.parentId ? departmentById.get(department.parentId) : undefined;
      while (current) {
        visible.add(current.id);
        current = current.parentId ? departmentById.get(current.parentId) : undefined;
      }
    });

    return visible;
  }, [childMap, departmentById, departments, normalizedSearch]);

  const statistics = useMemo(() => {
    return {
      roots: departments.filter((department) => department.hierarchyLevel <= 0).length,
      workshops: departments.filter((department) => department.hierarchyLevel === 1).length,
      areas: departments.filter((department) => department.hierarchyLevel >= 2).length,
      local: localDepartments.length
    };
  }, [departments, localDepartments.length]);

  const visibleRootNodes = rootNodes.filter((node) => visibleNodeIds.has(node.id));
  const isUsingFallback = apiDepartments.length === 0;

  const toggleNode = (nodeId: string): void => {
    setExpandedIds((current) => {
      const next = new Set(current);
      if (next.has(nodeId)) {
        next.delete(nodeId);
      } else {
        next.add(nodeId);
      }
      return next;
    });
  };

  const openCreateModal = (type: CreateFormState["type"] = "workshop", parentId = ""): void => {
    const options = type === "workshop" ? rootOptions : workshopOptions;
    const resolvedParentId = parentId || options[0]?.id || "";

    setCreateForm({
      type,
      parentId: resolvedParentId,
      name: "",
      shortName: ""
    });
    setIsCreateModalOpen(true);
  };

  const closeCreateModal = (): void => {
    setIsCreateModalOpen(false);
  };

  const handleSubmitCreate = (event: React.FormEvent<HTMLFormElement>): void => {
    event.preventDefault();

    const name = createForm.name.trim();
    const shortName = createForm.shortName.trim();
    const parent = departmentById.get(createForm.parentId);

    if (!name || !parent) return;

    const newDepartment: StructureNode = {
      id: createLocalId(),
      parentId: parent.id,
      name,
      shortName: shortName || name,
      hierarchyLevel: parent.hierarchyLevel + 1,
      isActive: true,
      source: "local"
    };

    setLocalDepartments((current) => {
      const nextDepartments = [...current, newDepartment];
      saveLocalDepartments(nextDepartments);
      return nextDepartments;
    });

    setExpandedIds((current) => new Set([...current, parent.id, newDepartment.id]));
    setIsCreateModalOpen(false);
  };

  const clearLocalDepartments = (): void => {
    setLocalDepartments([]);
    saveLocalDepartments([]);
  };

  const renderNode = (node: StructureNode, depth = 0): React.ReactNode => {
    const children = (childMap.get(node.id) ?? []).filter((child) => visibleNodeIds.has(child.id));
    const hasChildren = children.length > 0;
    const isExpanded = expandedIds.has(node.id);
    const canCreateWorkshop = node.hierarchyLevel <= 0;
    const canCreateArea = node.hierarchyLevel === 1;

    return (
      <React.Fragment key={node.id}>
        <div className="enterprise-structure-row" style={{ "--node-depth": depth } as React.CSSProperties}>
          <button
            type="button"
            className={hasChildren ? "enterprise-structure-toggle" : "enterprise-structure-toggle enterprise-structure-toggle--empty"}
            onClick={() => hasChildren && toggleNode(node.id)}
            aria-label={isExpanded ? "Свернуть" : "Развернуть"}
            disabled={!hasChildren}
          >
            <SvgIcon name="chevron-down" className={isExpanded ? "enterprise-structure-toggle__icon" : "enterprise-structure-toggle__icon enterprise-structure-toggle__icon--closed"} />
          </button>

          <span className="enterprise-structure-folder-icon" aria-hidden="true" />

          <div className="enterprise-structure-node-main">
            <div className="enterprise-structure-node-title-row">
              <span className="enterprise-structure-node-title">{getDisplayName(node)}</span>
              <span className={`enterprise-structure-badge ${getNodeBadgeClass(node.hierarchyLevel)}`}>
                {getNodeTypeLabel(node.hierarchyLevel)}
              </span>
            </div>
            {node.name !== node.shortName ? (
              <span className="enterprise-structure-node-subtitle">{node.name}</span>
            ) : null}
          </div>

          <div className="enterprise-structure-node-meta">
            <span>{children.length} влож.</span>
            {node.source === "local" ? <span className="enterprise-structure-local-mark">Локально</span> : null}
          </div>

          <div className="enterprise-structure-node-actions">
            {canCreateWorkshop ? (
              <button type="button" className="btn btn--ghost btn--small" onClick={() => openCreateModal("workshop", node.id)}>
                + Цех
              </button>
            ) : null}
            {canCreateArea ? (
              <button type="button" className="btn btn--ghost btn--small" onClick={() => openCreateModal("area", node.id)}>
                + Участок
              </button>
            ) : null}
          </div>
        </div>

        {hasChildren && isExpanded ? children.map((child) => renderNode(child, depth + 1)) : null}
      </React.Fragment>
    );
  };

  return (
    <div className="enterprise-structure-page">
      <div className="ui-page__header enterprise-structure-page__header">
        <div>
          <h1 className="ui-page__title">Структура предприятия</h1>
          
        </div>

        <div className="enterprise-structure-header-actions">
          <button type="button" className="btn btn--primary" onClick={() => openCreateModal("workshop")}>
            <span className="btn__plus">+</span>
            Создать подразделение
          </button>
        </div>
      </div>

      <div className="ui-divider" />

      <section className="enterprise-structure-stats">
        <div className="enterprise-structure-stat ui-card">
          <span className="enterprise-structure-stat__label">Главные департаменты</span>
          <strong>{statistics.roots}</strong>
        </div>
        <div className="enterprise-structure-stat ui-card">
          <span className="enterprise-structure-stat__label">Цеха</span>
          <strong>{statistics.workshops}</strong>
        </div>
        <div className="enterprise-structure-stat ui-card">
          <span className="enterprise-structure-stat__label">Участки</span>
          <strong>{statistics.areas}</strong>
        </div>
      </section>

      <section className="ui-card enterprise-structure-toolbar-card">
        <div className="ui-card__body enterprise-structure-toolbar">
          <div className="ui-search enterprise-structure-search">
            <span className="ui-search__icon">
              <SvgIcon name="search" />
            </span>
            <input
              className="ui-search__input"
              type="text"
              placeholder="Поиск по структуре..."
              value={searchValue}
              onChange={(event) => setSearchValue(event.target.value)}
            />
            {searchValue ? (
              <button type="button" className="ui-search__action" title="Очистить" onClick={() => setSearchValue("")}>
                <SvgIcon name="close" />
              </button>
            ) : null}
          </div>

          <div className="enterprise-structure-toolbar__actions">
            <button type="button" className="btn btn--ghost btn--small" onClick={() => openCreateModal("workshop")} disabled={rootOptions.length === 0}>
              + Цех
            </button>
            <button type="button" className="btn btn--ghost btn--small" onClick={() => openCreateModal("area")} disabled={workshopOptions.length === 0}>
              + Участок
            </button>
            {statistics.local > 0 ? (
              <button type="button" className="btn btn--ghost btn--small" onClick={clearLocalDepartments}>
                Очистить локальные
              </button>
            ) : null}
          </div>
        </div>
      </section>

      {errorMessage ? (
        <div className="enterprise-structure-note enterprise-structure-note--warning">
          {errorMessage}. Показана базовая структура, чтобы страницу можно было проверить без отдельного API структуры предприятия.
        </div>
      ) : null}

      {isUsingFallback && !isLoading && !errorMessage ? (
        <div className="enterprise-structure-note">
          Отдельного API для структуры предприятия нет, поэтому страница использует доступный контекст подразделений сотрудников и локальную логику создания.
        </div>
      ) : null}

      <section className="ui-card enterprise-structure-card">
        <div className="ui-card__header enterprise-structure-card__header">
          <div>
            <h2 className="ui-card__title">Список подразделений</h2>
            <p className="enterprise-structure-card__hint">
              Новые цеха и участки сохраняются в localStorage браузера до появления API создания подразделений.
            </p>
          </div>
        </div>

        <div className="enterprise-structure-tree">
          {isLoading ? (
            <div className="ui-empty">Загрузка структуры предприятия...</div>
          ) : visibleRootNodes.length > 0 ? (
            visibleRootNodes.map((node) => renderNode(node))
          ) : (
            <div className="ui-empty">Подразделения по выбранному поиску не найдены.</div>
          )}
        </div>
      </section>

      <AppModal
        open={isCreateModalOpen}
        title="Создать подразделение"
        onClose={closeCreateModal}
        actions={
          <>
            <button type="button" className="btn btn--ghost" onClick={closeCreateModal}>
              Отмена
            </button>
            <button type="submit" form="enterprise-structure-create-form" className="btn btn--primary" disabled={!createForm.name.trim() || !createForm.parentId}>
              Создать
            </button>
          </>
        }
      >
        <form id="enterprise-structure-create-form" className="enterprise-structure-form" onSubmit={handleSubmitCreate}>
          <div className="ui-field">
            <label className="ui-field__label" htmlFor="structure-type">Тип подразделения</label>
            <div className="ui-select-wrap">
              <select
                id="structure-type"
                className="ui-select"
                value={createForm.type}
                onChange={(event) => setCreateForm((current) => ({ ...current, type: event.target.value as CreateFormState["type"], parentId: "" }))}
              >
                <option value="workshop">Цех</option>
                <option value="area">Участок</option>
              </select>
              <SvgIcon name="chevron-down" className="ui-select-wrap__icon" />
            </div>
          </div>

          <div className="ui-field">
            <label className="ui-field__label" htmlFor="structure-parent">Родительское подразделение</label>
            <div className="ui-select-wrap">
              <select
                id="structure-parent"
                className="ui-select"
                value={createForm.parentId}
                onChange={(event) => setCreateForm((current) => ({ ...current, parentId: event.target.value }))}
                disabled={parentOptions.length === 0}
              >
                {parentOptions.length === 0 ? <option value="">Нет доступных родителей</option> : null}
                {parentOptions.map((department) => (
                  <option key={department.id} value={department.id}>
                    {getDisplayName(department)}
                  </option>
                ))}
              </select>
              <SvgIcon name="chevron-down" className="ui-select-wrap__icon" />
            </div>
          </div>

          <div className="ui-field">
            <label className="ui-field__label" htmlFor="structure-name">
              Название <span className="ui-field__required">*</span>
            </label>
            <input
              id="structure-name"
              className="ui-input"
              type="text"
              placeholder={createForm.type === "workshop" ? "Например, Цех №3" : "Например, Участок №8"}
              value={createForm.name}
              onChange={(event) => setCreateForm((current) => ({ ...current, name: event.target.value }))}
              autoFocus
            />
          </div>

          <div className="ui-field">
            <label className="ui-field__label" htmlFor="structure-short-name">Короткое название</label>
            <input
              id="structure-short-name"
              className="ui-input"
              type="text"
              placeholder="Можно оставить пустым"
              value={createForm.shortName}
              onChange={(event) => setCreateForm((current) => ({ ...current, shortName: event.target.value }))}
            />
          </div>
        </form>
      </AppModal>
    </div>
  );
}
