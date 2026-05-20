import React from "react";

type PaginationItem = number | string;

type UiPaginationProps = {
  currentPage: number;
  totalItems: number;
  pageSize: number;
  onPageChange: (page: number) => void;
  className?: string;
  ariaLabel?: string;
  previousLabel?: string;
  nextLabel?: string;
};

function getPaginationItems(totalPages: number, currentPage: number): PaginationItem[] {
  if (totalPages <= 7) {
    return Array.from({ length: totalPages }, (_, index) => index + 1);
  }

  const pages = new Set<number>([1, totalPages, currentPage]);

  if (currentPage > 1) pages.add(currentPage - 1);
  if (currentPage < totalPages) pages.add(currentPage + 1);
  if (currentPage <= 3) {
    pages.add(2);
    pages.add(3);
  }
  if (currentPage >= totalPages - 2) {
    pages.add(totalPages - 1);
    pages.add(totalPages - 2);
  }

  const sortedPages = Array.from(pages)
    .filter((page) => page >= 1 && page <= totalPages)
    .sort((a, b) => a - b);

  return sortedPages.reduce<PaginationItem[]>((items, page, index) => {
    const previousPage = sortedPages[index - 1];
    if (index > 0 && previousPage && page - previousPage > 1) {
      items.push(`ellipsis-${previousPage}-${page}`);
    }
    items.push(page);
    return items;
  }, []);
}

export function UiPagination({
  currentPage,
  totalItems,
  pageSize,
  onPageChange,
  className = "",
  ariaLabel = "Пагинация",
  previousLabel = "Назад",
  nextLabel = "Вперёд",
}: UiPaginationProps): React.ReactElement | null {
  if (totalItems <= 0 || pageSize <= 0) {
    return null;
  }

  const totalPages = Math.max(1, Math.ceil(totalItems / pageSize));
  const safeCurrentPage = Math.min(Math.max(1, currentPage), totalPages);
  const pageStartIndex = (safeCurrentPage - 1) * pageSize;
  const pageEndIndex = Math.min(pageStartIndex + pageSize, totalItems);
  const paginationItems = getPaginationItems(totalPages, safeCurrentPage);

  return (
    <nav className={`ui-pagination ${className}`.trim()} aria-label={ariaLabel}>
      <div className="ui-pagination__summary">
        Показаны {pageStartIndex + 1}–{pageEndIndex} из {totalItems}
      </div>
      <div className="ui-pagination__controls">
        <button
          type="button"
          className="ui-pagination__button"
          onClick={() => onPageChange(Math.max(1, safeCurrentPage - 1))}
          disabled={safeCurrentPage === 1}
        >
          {previousLabel}
        </button>

        {paginationItems.map((item) =>
          typeof item === "number" ? (
            <button
              key={item}
              type="button"
              className={`ui-pagination__button ${item === safeCurrentPage ? "ui-pagination__button--active" : ""}`.trim()}
              aria-current={item === safeCurrentPage ? "page" : undefined}
              onClick={() => onPageChange(item)}
            >
              {item}
            </button>
          ) : (
            <span key={item} className="ui-pagination__ellipsis">
              …
            </span>
          ),
        )}

        <button
          type="button"
          className="ui-pagination__button"
          onClick={() => onPageChange(Math.min(totalPages, safeCurrentPage + 1))}
          disabled={safeCurrentPage === totalPages}
        >
          {nextLabel}
        </button>
      </div>
    </nav>
  );
}
