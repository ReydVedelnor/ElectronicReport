import React, { useEffect, useMemo, useRef, useState } from "react";
import { useNavigate } from "react-router";
import { SvgIcon } from "~/components/svg-icon";
import { UiPagination } from "~/components/ui-pagination";
import {
  fetchReportDepartments,
  fetchReportPeriod,
  type EmployeeDepartmentOptionResponse,
  type ReportPeriodColumnResponse
} from "~/components/reportApi";
import { getStoredAuthUser } from "~/lib/auth";

type DatePeriodMode = "all" | "single" | "range";

const ALL_REPORTS_DATE_FROM = "2000-01-01";
const REPORTS_PAGE_SIZE = 10;

type ReportsArchiveRow = {
  id: string;
  date: string;
  departmentId: string;
  departmentName: string;
  departmentShortName: string;
};

function getTodayIsoDate(): string {
  const now = new Date();
  const timezoneOffsetMs = now.getTimezoneOffset() * 60_000;
  return new Date(now.getTime() - timezoneOffsetMs).toISOString().slice(0, 10);
}

function formatRussianDate(value: string): string {
  const date = new Date(`${value}T00:00:00`);
  if (Number.isNaN(date.getTime())) return value;

  return date.toLocaleDateString("ru-RU", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric"
  });
}

function formatDatePeriodLabel(dateFrom: string, dateTo: string): string {
  if (!dateFrom && !dateTo) return "Выберите дату";
  if (dateFrom && (!dateTo || dateFrom === dateTo)) return `За ${formatRussianDate(dateFrom)}`;
  if (!dateFrom && dateTo) return `До ${formatRussianDate(dateTo)}`;

  return `${formatRussianDate(dateFrom)} — ${formatRussianDate(dateTo)}`;
}

function getDepartmentLabel(department: EmployeeDepartmentOptionResponse): string {
  return department.shortName?.trim() || department.name || "Без названия";
}

function normalizeDepartmentSearch(value: string): string {
  return value.trim().toLowerCase();
}

function hasReportData(column: ReportPeriodColumnResponse): boolean {
  return column.columnStatus === "HAS_SHIFT" || Boolean(column.reportId || column.shiftId);
}

function mergeArchiveRows(rows: ReportsArchiveRow[]): ReportsArchiveRow[] {
  const merged = new Map<string, ReportsArchiveRow>();

  rows.forEach((row) => {
    const key = `${row.departmentId}_${row.date}`;
    const current = merged.get(key);

    if (!current) {
      merged.set(key, row);
      return;
    }

    merged.set(key, {
      ...current,
      departmentName: current.departmentName || row.departmentName,
      departmentShortName:
        current.departmentShortName || row.departmentShortName,
    });
  });

  return Array.from(merged.values()).sort((a, b) => {
    const dateCompare = b.date.localeCompare(a.date);
    if (dateCompare !== 0) return dateCompare;
    return a.departmentShortName.localeCompare(b.departmentShortName, "ru");
  });
}

function buildRowsFromPeriod(
  department: EmployeeDepartmentOptionResponse,
  columns: ReportPeriodColumnResponse[],
): ReportsArchiveRow[] {
  const departmentShortName = getDepartmentLabel(department);
  const departmentName = department.name || departmentShortName;
  const rows = columns
    .filter(hasReportData)
    .map((column) => column.date)
    .filter(Boolean)
    .map((date) => ({
      id: `${date}_${department.departmentId}`,
      date,
      departmentId: department.departmentId,
      departmentName,
      departmentShortName,
    }));

  return mergeArchiveRows(rows);
}

function isDuplicateShiftError(error: unknown): boolean {
  const message = error instanceof Error ? error.message : String(error ?? "");
  return message.toLowerCase().includes("несколько смен");
}

function parseIsoDate(value: string): Date {
  return new Date(`${value}T00:00:00Z`);
}

function formatIsoDate(date: Date): string {
  return date.toISOString().slice(0, 10);
}

function addDays(value: string, days: number): string {
  const date = parseIsoDate(value);
  date.setUTCDate(date.getUTCDate() + days);
  return formatIsoDate(date);
}

function getDateDiffInDays(dateFrom: string, dateTo: string): number {
  const start = parseIsoDate(dateFrom).getTime();
  const end = parseIsoDate(dateTo).getTime();
  return Math.round((end - start) / 86_400_000);
}

function getMiddleDate(dateFrom: string, dateTo: string): string {
  const diffInDays = getDateDiffInDays(dateFrom, dateTo);
  return addDays(dateFrom, Math.floor(diffInDays / 2));
}

function buildMergedDuplicateRow(
  department: EmployeeDepartmentOptionResponse,
  date: string,
): ReportsArchiveRow {
  const departmentShortName = getDepartmentLabel(department);
  const departmentName = department.name || departmentShortName;

  return {
    id: `${date}_${department.departmentId}`,
    date,
    departmentId: department.departmentId,
    departmentName,
    departmentShortName,
  };
}

async function loadRowsFromPeriodSafely(
  department: EmployeeDepartmentOptionResponse,
  dateFrom: string,
  dateTo: string,
): Promise<ReportsArchiveRow[]> {
  try {
    const period = await fetchReportPeriod(
      department.departmentId,
      dateFrom,
      dateTo,
    );
    return buildRowsFromPeriod(department, period.columns ?? []);
  } catch (error) {
    if (!isDuplicateShiftError(error)) {
      throw error;
    }

    if (dateFrom === dateTo) {
      return [buildMergedDuplicateRow(department, dateFrom)];
    }

    const middleDate = getMiddleDate(dateFrom, dateTo);
    const nextDate = addDays(middleDate, 1);

    const [leftRows, rightRows] = await Promise.all([
      loadRowsFromPeriodSafely(department, dateFrom, middleDate),
      loadRowsFromPeriodSafely(department, nextDate, dateTo),
    ]);

    return mergeArchiveRows([...leftRows, ...rightRows]);
  }
}

export default function ReportsPage(): React.ReactElement {
  const navigate = useNavigate();
  const authUser = useMemo(() => getStoredAuthUser(), []);
  const today = useMemo(() => getTodayIsoDate(), []);
  const datePickerRef = useRef<HTMLDivElement | null>(null);

  const [dateFrom, setDateFrom] = useState(today);
  const [dateTo, setDateTo] = useState(today);
  const [isAllReportsMode, setIsAllReportsMode] = useState(true);
  const [datePeriodMode, setDatePeriodMode] = useState<DatePeriodMode>("all");
  const [draftDateFrom, setDraftDateFrom] = useState(today);
  const [draftDateTo, setDraftDateTo] = useState(today);
  const [isDatePickerOpen, setIsDatePickerOpen] = useState(false);
  const [departmentId, setDepartmentId] = useState("all");
  const [searchValue, setSearchValue] = useState("");
  const [departments, setDepartments] = useState<EmployeeDepartmentOptionResponse[]>([]);
  const [archiveRowsFromDb, setArchiveRowsFromDb] = useState<ReportsArchiveRow[]>([]);
  const [isDepartmentsLoading, setIsDepartmentsLoading] = useState(true);
  const [isReportsLoading, setIsReportsLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState("");
  const [currentPage, setCurrentPage] = useState(1);

  useEffect(() => {
    if (!isDatePickerOpen) {
      return undefined;
    }

    const handlePointerDown = (event: MouseEvent) => {
      if (!datePickerRef.current) return;
      if (datePickerRef.current.contains(event.target as Node)) return;
      setIsDatePickerOpen(false);
    };

    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        setIsDatePickerOpen(false);
      }
    };

    document.addEventListener("mousedown", handlePointerDown);
    document.addEventListener("keydown", handleKeyDown);

    return () => {
      document.removeEventListener("mousedown", handlePointerDown);
      document.removeEventListener("keydown", handleKeyDown);
    };
  }, [isDatePickerOpen]);

  useEffect(() => {
    let isMounted = true;

    const loadDepartments = async () => {
      if (!authUser?.userId) {
        setErrorMessage("Не удалось определить текущего пользователя. Выполните вход заново.");
        setIsDepartmentsLoading(false);
        return;
      }

      try {
        setIsDepartmentsLoading(true);
        setErrorMessage("");

        const context = await fetchReportDepartments(authUser.userId);
        const activeDepartments = (context.departments ?? [])
          .filter((department) => department.departmentId && department.isActive !== false)
          .sort((a, b) => getDepartmentLabel(a).localeCompare(getDepartmentLabel(b), "ru"));

        if (!isMounted) return;

        setDepartments(activeDepartments);
        if (activeDepartments.length === 1) {
          setDepartmentId(activeDepartments[0].departmentId);
        }
      } catch (error) {
        if (!isMounted) return;
        setDepartments([]);
        setErrorMessage(error instanceof Error ? error.message : "Не удалось загрузить подразделения.");
      } finally {
        if (isMounted) {
          setIsDepartmentsLoading(false);
        }
      }
    };

    void loadDepartments();

    return () => {
      isMounted = false;
    };
  }, [authUser?.userId]);

  const requestedDateFrom = isAllReportsMode ? ALL_REPORTS_DATE_FROM : dateFrom;
  const requestedDateTo = isAllReportsMode ? today : dateTo;
  const isInvalidRange = !isAllReportsMode && Boolean(dateFrom && dateTo && dateFrom > dateTo);
  const datePeriodLabel = isAllReportsMode ? "Все существующие рапорты" : formatDatePeriodLabel(dateFrom, dateTo);

  useEffect(() => {
    let isMounted = true;

    const loadReports = async () => {
      if (isDepartmentsLoading || isInvalidRange) {
        setArchiveRowsFromDb([]);
        return;
      }

      const selectedDepartments = departments.filter((department) => {
        if (departmentId === "all") return true;
        return department.departmentId === departmentId;
      });

      if (selectedDepartments.length === 0) {
        setArchiveRowsFromDb([]);
        return;
      }

      try {
        setIsReportsLoading(true);
        setErrorMessage("");

        const settledResults = await Promise.allSettled(
          selectedDepartments.map((department) =>
            loadRowsFromPeriodSafely(
              department,
              requestedDateFrom,
              requestedDateTo,
            ),
          ),
        );

        if (!isMounted) return;

        const loadedRows = mergeArchiveRows(
          settledResults.flatMap((result) =>
            result.status === "fulfilled" ? result.value : [],
          ),
        );

        setArchiveRowsFromDb(loadedRows);

        const failedCount = settledResults.filter((result) => result.status === "rejected").length;
        if (failedCount === selectedDepartments.length) {
          const firstError = settledResults.find((result) => result.status === "rejected");
          const reason = firstError?.status === "rejected" ? firstError.reason : null;
          setErrorMessage(reason instanceof Error ? reason.message : "Не удалось загрузить список рапортов из БД.");
        } else if (failedCount > 0) {
          setErrorMessage("Часть подразделений не удалось загрузить. Показаны доступные рапорты.");
        }
      } catch (error) {
        if (!isMounted) return;
        setArchiveRowsFromDb([]);
        setErrorMessage(error instanceof Error ? error.message : "Не удалось загрузить список рапортов из БД.");
      } finally {
        if (isMounted) {
          setIsReportsLoading(false);
        }
      }
    };

    void loadReports();

    return () => {
      isMounted = false;
    };
  }, [departmentId, departments, isDepartmentsLoading, isInvalidRange, requestedDateFrom, requestedDateTo]);

  const archiveRows = useMemo<ReportsArchiveRow[]>(() => {
    const normalizedSearch = normalizeDepartmentSearch(searchValue);

    if (!normalizedSearch) return archiveRowsFromDb;

    return archiveRowsFromDb.filter((row) => {
      const fullName = row.departmentName.toLowerCase();
      const shortName = row.departmentShortName.toLowerCase();
      return fullName.includes(normalizedSearch) || shortName.includes(normalizedSearch);
    });
  }, [archiveRowsFromDb, searchValue]);

  const totalReportsCount = archiveRows.length;
  const totalPages = Math.max(1, Math.ceil(totalReportsCount / REPORTS_PAGE_SIZE));
  const safeCurrentPage = Math.min(currentPage, totalPages);
  const pageStartIndex = (safeCurrentPage - 1) * REPORTS_PAGE_SIZE;
  const paginatedArchiveRows = archiveRows.slice(pageStartIndex, pageStartIndex + REPORTS_PAGE_SIZE);

  useEffect(() => {
    setCurrentPage(1);
  }, [departmentId, searchValue, requestedDateFrom, requestedDateTo]);

  useEffect(() => {
    if (currentPage > totalPages) {
      setCurrentPage(totalPages);
    }
  }, [currentPage, totalPages]);

  const isLoading = isDepartmentsLoading || isReportsLoading;

  const handleDatePickerToggle = (): void => {
    setDraftDateFrom(dateFrom || today);
    setDraftDateTo(dateTo || dateFrom || today);
    setDatePeriodMode(isAllReportsMode ? "all" : dateFrom && dateTo && dateFrom !== dateTo ? "range" : "single");
    setIsDatePickerOpen((prev) => !prev);
  };

  const handleApplyDatePeriod = (): void => {
    if (datePeriodMode === "all") {
      setIsAllReportsMode(true);
      setIsDatePickerOpen(false);
      return;
    }

    setIsAllReportsMode(false);

    if (datePeriodMode === "single") {
      const selectedDate = draftDateFrom || draftDateTo || today;
      setDateFrom(selectedDate);
      setDateTo(selectedDate);
      setIsDatePickerOpen(false);
      return;
    }

    const selectedFrom = draftDateFrom || draftDateTo || today;
    const selectedTo = draftDateTo || draftDateFrom || selectedFrom;

    if (selectedFrom > selectedTo) {
      setDateFrom(selectedTo);
      setDateTo(selectedFrom);
    } else {
      setDateFrom(selectedFrom);
      setDateTo(selectedTo);
    }

    setIsDatePickerOpen(false);
  };

  const handleResetDatePeriod = (): void => {
    setDatePeriodMode("all");
    setDraftDateFrom(today);
    setDraftDateTo(today);
    setIsAllReportsMode(true);
    setIsDatePickerOpen(false);
  };

  const handleSelectToday = (): void => {
    setDatePeriodMode("single");
    setDraftDateFrom(today);
    setDraftDateTo(today);
    setDateFrom(today);
    setDateTo(today);
    setIsAllReportsMode(false);
    setIsDatePickerOpen(false);
  };

  const handleOpenReport = (row: ReportsArchiveRow): void => {
    const params = new URLSearchParams({
      departmentId: row.departmentId,
      departmentName: row.departmentName,
      date: row.date
    });

    navigate(`/reports/view?${params.toString()}`);
  };

  return (
    <div className="reports-page">
      <div className="ui-page__header reports-page__header">
        <div>
          <h1 className="ui-page__title">Рапорты</h1>
        </div>
      </div>

      <div className="ui-divider" />

      <section className="ui-card reports-filter-card">
        <div className="ui-card__body reports-filters">
          <div className="ui-field reports-filter-field reports-filter-field--period">
            <label className="ui-field__label" htmlFor="reports-date-period">Период рапортов</label>
            <div className="reports-date-period" ref={datePickerRef}>
              <button
                id="reports-date-period"
                type="button"
                className={`reports-date-period__trigger ${isDatePickerOpen ? "reports-date-period__trigger--open" : ""}`}
                aria-haspopup="dialog"
                aria-expanded={isDatePickerOpen}
                onClick={handleDatePickerToggle}
              >
                <span className="reports-date-period__trigger-copy">
                  <SvgIcon name="paper" className="reports-date-period__trigger-icon" />
                  <span>{datePeriodLabel}</span>
                </span>
                <SvgIcon name="chevron-down" className="reports-date-period__trigger-chevron" />
              </button>

              {isDatePickerOpen ? (
                <div className="reports-date-period__panel" role="dialog" aria-label="Выбор периода рапортов">
                  <div className="reports-date-period__tabs reports-date-period__tabs--three" role="tablist" aria-label="Тип периода">
                    <button
                      type="button"
                      className={`reports-date-period__tab ${datePeriodMode === "all" ? "reports-date-period__tab--active" : ""}`}
                      aria-selected={datePeriodMode === "all"}
                      onClick={() => setDatePeriodMode("all")}
                    >
                      Все
                    </button>
                    <button
                      type="button"
                      className={`reports-date-period__tab ${datePeriodMode === "single" ? "reports-date-period__tab--active" : ""}`}
                      aria-selected={datePeriodMode === "single"}
                      onClick={() => {
                        setDatePeriodMode("single");
                        setDraftDateTo(draftDateFrom || today);
                      }}
                    >
                      Один день
                    </button>
                    <button
                      type="button"
                      className={`reports-date-period__tab ${datePeriodMode === "range" ? "reports-date-period__tab--active" : ""}`}
                      aria-selected={datePeriodMode === "range"}
                      onClick={() => {
                        setDatePeriodMode("range");
                        setDraftDateTo(draftDateTo || draftDateFrom || today);
                      }}
                    >
                      Период
                    </button>
                  </div>

                  {datePeriodMode === "all" ? (
                    <div className="reports-date-period__hint">
                      Будут загружены все рапорты, найденные в БД для доступных подразделений.
                    </div>
                  ) : datePeriodMode === "single" ? (
                    <div className="ui-field reports-date-period__field">
                      <label className="ui-field__label" htmlFor="reports-single-date">Дата рапорта</label>
                      <input
                        id="reports-single-date"
                        className="ui-input"
                        type="date"
                        value={draftDateFrom}
                        onChange={(event) => {
                          setDraftDateFrom(event.target.value);
                          setDraftDateTo(event.target.value);
                        }}
                      />
                    </div>
                  ) : (
                    <div className="reports-date-period__range">
                      <div className="ui-field reports-date-period__field">
                        <label className="ui-field__label" htmlFor="reports-range-from">Дата с</label>
                        <input
                          id="reports-range-from"
                          className="ui-input"
                          type="date"
                          value={draftDateFrom}
                          onChange={(event) => setDraftDateFrom(event.target.value)}
                        />
                      </div>
                      <div className="ui-field reports-date-period__field">
                        <label className="ui-field__label" htmlFor="reports-range-to">Дата по</label>
                        <input
                          id="reports-range-to"
                          className="ui-input"
                          type="date"
                          value={draftDateTo}
                          onChange={(event) => setDraftDateTo(event.target.value)}
                        />
                      </div>
                    </div>
                  )}

                  <div className="reports-date-period__hint">
                    По умолчанию показываются все найденные рапорты. При необходимости выберите день или период.
                  </div>

                  <div className="reports-date-period__actions">
                    <button type="button" className="btn btn--ghost btn--small" onClick={handleResetDatePeriod}>
                      Все рапорты
                    </button>
                    <button type="button" className="btn btn--ghost btn--small" onClick={handleSelectToday}>
                      Сегодня
                    </button>
                    <button type="button" className="btn btn--primary btn--small" onClick={handleApplyDatePeriod}>
                      Применить
                    </button>
                  </div>
                </div>
              ) : null}
            </div>
          </div>

          <div className="ui-field reports-filter-field reports-filter-field--department">
            <label className="ui-field__label" htmlFor="reports-department">Подразделение</label>
            <div className="ui-select-wrap reports-select-wrap">
              <select
                id="reports-department"
                className="ui-select"
                value={departmentId}
                onChange={(event) => setDepartmentId(event.target.value)}
                disabled={isLoading || departments.length === 0}
              >
                <option value="all">Все доступные подразделения</option>
                {departments.map((department) => (
                  <option key={department.departmentId} value={department.departmentId}>
                    {getDepartmentLabel(department)}
                  </option>
                ))}
              </select>
              <SvgIcon name="chevron-down" className="ui-select-wrap__icon" />
            </div>
          </div>

          <div className="ui-search reports-searchbar">
            <span className="ui-search__icon">
              <SvgIcon name="search" />
            </span>
            <input
              className="ui-search__input"
              type="text"
              placeholder="Поиск подразделения..."
              value={searchValue}
              onChange={(event) => setSearchValue(event.target.value)}
            />
            <button type="button" className="ui-search__action" title="Фильтр" aria-label="Фильтр">
              <SvgIcon name="filter" />
            </button>
          </div>
        </div>
      </section>

      {isInvalidRange ? (
        <div className="reports-inline-note reports-inline-note--warning">
          Дата начала периода не может быть позже даты окончания.
        </div>
      ) : null}


      <section className="ui-card reports-card">
        <div className="ui-card__header">
          <div>
            <h2 className="ui-card__title">Список рапортов</h2>
            
          </div>
        </div>

        <div className="ui-table-wrap">
          <table className="ui-table reports-list-table">
            <thead>
              <tr>
                <th className="reports-list-table__num">№</th>
                <th className="reports-list-table__date">Дата</th>
                <th>Подразделение</th>
                <th className="reports-list-table__actions">Действия</th>
              </tr>
            </thead>
            <tbody>
              {isLoading ? (
                <tr>
                  <td colSpan={4} className="ui-empty">Загрузка списка рапортов...</td>
                </tr>
              ) : errorMessage && archiveRows.length === 0 ? (
                <tr>
                  <td colSpan={4} className="ui-empty">{errorMessage}</td>
                </tr>
              ) : archiveRows.length > 0 ? (
                paginatedArchiveRows.map((row, index) => (
                  <tr key={row.id}>
                    <td>{pageStartIndex + index + 1}</td>
                    <td className="reports-list-table__date-cell">{formatRussianDate(row.date)}</td>
                    <td>
                      <div className="reports-department-cell">
                        <span className="reports-department-cell__title">{row.departmentShortName}</span>
                        {row.departmentName !== row.departmentShortName ? (
                          <span className="reports-department-cell__subtitle">{row.departmentName}</span>
                        ) : null}
                      </div>
                    </td>
                    <td>
                      <button type="button" className="btn btn--primary btn--small" onClick={() => handleOpenReport(row)}>
                        Открыть
                      </button>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={4} className="ui-empty">Рапорты по выбранным условиям не найдены.</td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        {!isLoading ? (
          <UiPagination
            currentPage={safeCurrentPage}
            totalItems={totalReportsCount}
            pageSize={REPORTS_PAGE_SIZE}
            onPageChange={setCurrentPage}
            className="ui-pagination--attached"
            ariaLabel="Пагинация списка рапортов"
          />
        ) : null}

        {errorMessage && archiveRows.length > 0 ? (
          <div className="reports-card__footer-note">{errorMessage}</div>
        ) : null}
      </section>
    </div>
  );
}
