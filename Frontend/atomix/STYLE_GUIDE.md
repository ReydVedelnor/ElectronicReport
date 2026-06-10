# Единая система стилей

## Что вынесено
- `app/styles/tokens.css` — цвета, радиусы, тени, отступы, базовые переменные.
- `app/styles/layout.css` — общий layout приложения, sidebar, content shell.
- `app/styles/ui.css` — переиспользуемые кнопки, поля, таблицы, карточки, модальные окна, toast.
- `app/styles/templates.css` — стили страниц шаблонов.
- `app/styles/dashboard.css` — стили страницы отчёта за смену.
- `app/styles/employees.css` — стили страницы сотрудников.
- `app/styles/employees-modal.css` — стили модального окна сотрудника.
- `app/styles/login.css` — стили страницы входа.
- `app/styles/role-system.css` — стили ролевой системы.
- `app/styles/placeholders.css` — базовый вид простых контентных страниц.
- `app/components/svg-icon.tsx` — единый способ подключения SVG-иконок из `public/icons`.
- `app/components/app-modal.tsx` — базовая заготовка для всех будущих модальных окон системы.
- `app/components/ui-pagination.tsx` — общий компонент пагинации для списков и таблиц.

Все стили подключаются централизованно через `app/app.css`.

## Правила по иконкам
1. Все иконки должны лежать только в `public/icons`.
2. Каждая иконка — отдельный SVG-файл.
3. Не использовать React-иконки, icon-font и inline SVG прямо в страницах.
4. Для вывода иконки использовать `SvgIcon`.

Пример:

```tsx
<SvgIcon name="search" />
<SvgIcon name="close" width={20} height={20} />
```

## Как делать новые страницы

### 1. Для обычной страницы

```tsx
<section className="page">
  <h1 className="page__title">Заголовок</h1>
  <p className="page__text">Описание страницы</p>
</section>
```

### 2. Для страницы с тулбаром

```tsx
<div className="ui-page">
  <div className="ui-toolbar">
    <div className="ui-toolbar__group">
      <button className="btn btn--success">Сохранить</button>
    </div>

    <div className="ui-search">
      <span className="ui-search__icon">
        <SvgIcon name="search" />
      </span>
      <input className="ui-search__input" placeholder="Поиск..." />
    </div>
  </div>
</div>
```

### 3. Для select

```tsx
<div className="ui-select-wrap">
  <select className="ui-select">
    <option>Вариант</option>
  </select>
  <SvgIcon name="chevron-down" className="ui-select-wrap__icon" />
</div>
```

### 4. Для карточек и таблиц

```tsx
<div className="ui-card">
  <div className="ui-card__header">
    <h2 className="ui-card__title">Заголовок блока</h2>
  </div>

  <div className="ui-table-wrap">
    <table className="ui-table">...</table>
  </div>
</div>
```

### 5. Для модальных окон
Использовать `AppModal` как базовый шаблон для всех новых confirm/info modal.

```tsx
<AppModal
  open={isOpen}
  title="Заголовок"
  description="Текст модального окна"
  onClose={() => setIsOpen(false)}
  bodyAlign="center"
  actions={
    <>
      <button type="button" className="btn btn--ghost" onClick={() => setIsOpen(false)}>
        Нет
      </button>
      <button type="button" className="btn btn--success" onClick={handleConfirm}>
        Да
      </button>
    </>
  }
/>
```

Что уже входит в общий шаблон модалки:
- затемнение фона
- белая карточка с общей рамкой и тенью
- header с заголовком и кнопкой закрытия
- body с обычным или центрированным текстом
- footer с кнопками действий
- единые hover-состояния


### 6. Для выпадающего меню фильтра

Для страниц с фильтрацией использовать общий шаблон `ui-filter-menu`. Выбранные значения при необходимости дополнительно выводить через `ui-toolbar-meta` и `ui-filter-chip`.

```tsx
<div className="ui-filter-menu">
  <button type="button" className="ui-filter-menu__trigger" aria-expanded={isOpen}>
    <span className="ui-filter-menu__trigger-icon"><SvgIcon name="filter" /></span>
    <span>Фильтры</span>
    {hasActiveFilters ? <span className="ui-filter-menu__counter">1</span> : null}
    <SvgIcon name="chevron-down" className="ui-filter-menu__trigger-chevron" />
  </button>

  {isOpen ? (
    <div className="ui-filter-menu__panel">
      <aside className="ui-filter-menu__sidebar">
        <div className="ui-filter-menu__sidebar-title">Фильтры</div>
        <button type="button" className="ui-filter-menu__section ui-filter-menu__section--active">
          Состояние
        </button>
        <button type="button" className="ui-filter-menu__section">
          Подразделение
        </button>
      </aside>

      <div className="ui-filter-menu__content">
        <div className="ui-filter-menu__content-head">
          <div className="ui-filter-menu__content-copy">
            <h3 className="ui-filter-menu__content-title">Состояние</h3>
          </div>

          <button type="button" className="ui-filter-menu__reset">Сбросить</button>
        </div>

        <div className="ui-filter-menu__options">
          <button type="button" className="ui-filter-menu__option ui-filter-menu__option--active">
            <span className="ui-filter-menu__option-copy">
              <span className="ui-filter-menu__option-title">Все записи</span>
            </span>
            <span className="ui-filter-menu__option-mark ui-filter-menu__option-mark--active"><SvgIcon name="check" /></span>
          </button>

          <button type="button" className="ui-filter-menu__option">
            <span className="ui-filter-menu__option-copy">
              <span className="ui-filter-menu__option-title">Активные</span>
            </span>
            <span className="ui-filter-menu__option-mark" />
          </button>
        </div>
      </div>
    </div>
  ) : null}
</div>

<div className="ui-toolbar-meta">
  <div className="ui-filter-chip">
    <span className="ui-filter-chip__icon"><SvgIcon name="filter" /></span>
    <span>Активные</span>
    <button className="ui-filter-chip__remove" type="button"><SvgIcon name="close" /></button>
  </div>
</div>
```
### 7. Для пагинации списков и таблиц

Использовать общий компонент `UiPagination` и классы `ui-pagination*` из `ui.css`.
Для пагинации, прикреплённой к низу карточки/таблицы, добавлять модификатор `ui-pagination--attached`.

```tsx
<UiPagination
  currentPage={currentPage}
  totalItems={items.length}
  pageSize={10}
  onPageChange={setCurrentPage}
  className="ui-pagination--attached"
  ariaLabel="Пагинация списка"
/>
```

## Правила для будущих страниц
1. Сначала собирать страницу на базе классов из `ui.css`.
2. Если не хватает общего паттерна — добавлять его в `ui.css` или в общий компонент, а не локально в одной странице.
3. Если это уникальная страница — создавать отдельный файл в `app/styles/`.
4. Не использовать inline-style, если это не временный прототип.
5. Верхние панели по умолчанию собирать слева, если нет отдельного требования.
6. Таблицы, поиск, select и кнопки должны использовать единые базовые классы `ui-*` и `btn`.

