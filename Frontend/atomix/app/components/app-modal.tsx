import type { ReactNode } from "react";
import { SvgIcon } from "~/components/svg-icon";

type AppModalProps = {
  open: boolean;
  title: string;
  description?: string;
  onClose?: () => void;
  children?: ReactNode;
  actions?: ReactNode;
  bodyAlign?: "left" | "center";
  className?: string;
  panelClassName?: string;
  closeOnOverlayClick?: boolean;
};

export function AppModal({
  open,
  title,
  description,
  onClose,
  children,
  actions,
  bodyAlign = "left",
  className = "",
  panelClassName = "",
  closeOnOverlayClick = false,
}: AppModalProps) {
  if (!open) return null;

  const overlayClassName = ["modal-overlay", "app-modal-overlay", className].filter(Boolean).join(" ");
  const containerClassName = ["modal-container", "app-modal", panelClassName].filter(Boolean).join(" ");
  const bodyClassName = [
    "modal-body",
    "app-modal__body",
    bodyAlign === "center" ? "app-modal__body--center" : "",
  ]
    .filter(Boolean)
    .join(" ");

  const handleOverlayClick = () => {
    if (closeOnOverlayClick && onClose) onClose();
  };

  return (
    <div className={overlayClassName} onClick={handleOverlayClick}>
      <div className={containerClassName} onClick={(e) => e.stopPropagation()}>
        <div className="modal-header app-modal__header">
          <h2>{title}</h2>
          {onClose ? (
            <button type="button" className="modal-close app-modal__close" onClick={onClose} aria-label="Закрыть">
              <SvgIcon name="close" width={20} height={20} />
            </button>
          ) : null}
        </div>

        {description ? <div className={bodyClassName}>{description}</div> : null}
        {children ? <div className={bodyClassName}>{children}</div> : null}

        {actions ? <div className="modal-actions app-modal__actions">{actions}</div> : null}
      </div>
    </div>
  );
}
