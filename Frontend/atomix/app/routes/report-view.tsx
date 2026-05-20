import React, { useEffect, useMemo, useRef, useState } from "react";
import { useLocation, useNavigate } from "react-router";
import { SvgIcon } from "~/components/svg-icon";
import { fetchDailyReportPdf } from "~/components/reportApi";

declare global {
  interface Window {
    pdfjsLib?: any;
  }
}

const PDF_JS_SCRIPT_ID = "atomix-pdf-js";
const PDF_JS_VERSION = "3.11.174";
const PDF_JS_SCRIPT_URL = `https://cdnjs.cloudflare.com/ajax/libs/pdf.js/${PDF_JS_VERSION}/pdf.min.js`;
const PDF_JS_WORKER_URL = `https://cdnjs.cloudflare.com/ajax/libs/pdf.js/${PDF_JS_VERSION}/pdf.worker.min.js`;

function formatRussianDate(value?: string | null): string {
  if (!value) return "—";
  const date = new Date(`${value}T00:00:00`);
  if (Number.isNaN(date.getTime())) return value;

  return date.toLocaleDateString("ru-RU", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric"
  });
}

function loadScript(src: string, id: string): Promise<void> {
  return new Promise((resolve, reject) => {
    const existingScript = document.getElementById(id) as HTMLScriptElement | null;

    if (existingScript?.dataset.loaded === "true") {
      resolve();
      return;
    }

    if (existingScript) {
      existingScript.addEventListener("load", () => resolve(), { once: true });
      existingScript.addEventListener("error", () => reject(new Error("Не удалось загрузить модуль просмотра PDF.")), { once: true });
      return;
    }

    const script = document.createElement("script");
    script.id = id;
    script.src = src;
    script.async = true;
    script.onload = () => {
      script.dataset.loaded = "true";
      resolve();
    };
    script.onerror = () => reject(new Error("Не удалось загрузить модуль просмотра PDF."));

    document.head.appendChild(script);
  });
}

async function getPdfJs(): Promise<any> {
  if (!window.pdfjsLib) {
    await loadScript(PDF_JS_SCRIPT_URL, PDF_JS_SCRIPT_ID);
  }

  if (!window.pdfjsLib) {
    throw new Error("Модуль просмотра PDF недоступен.");
  }

  window.pdfjsLib.GlobalWorkerOptions.workerSrc = PDF_JS_WORKER_URL;
  return window.pdfjsLib;
}

function clearElement(element: HTMLElement | null): void {
  if (!element) return;
  element.replaceChildren();
}

export default function ReportViewPage(): React.ReactElement {
  const navigate = useNavigate();
  const location = useLocation();
  const pagesRef = useRef<HTMLDivElement | null>(null);
  const params = useMemo(() => new URLSearchParams(location.search), [location.search]);
  const departmentId = params.get("departmentId") ?? "";
  const departmentName = params.get("departmentName") ?? "—";
  const date = params.get("date") ?? "";

  const [pdfBlob, setPdfBlob] = useState<Blob | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [errorMessage, setErrorMessage] = useState("");

  useEffect(() => {
    let isMounted = true;

    const loadReportPdf = async () => {
      if (!departmentId || !date) {
        setPdfBlob(null);
        setErrorMessage("Не удалось открыть рапорт: не указаны дата или подразделение.");
        setIsLoading(false);
        return;
      }

      try {
        setIsLoading(true);
        setErrorMessage("");
        setPdfBlob(null);
        clearElement(pagesRef.current);

        const loadedPdfBlob = await fetchDailyReportPdf(departmentId, date);

        if (!isMounted) return;
        setPdfBlob(loadedPdfBlob);
      } catch (error) {
        if (!isMounted) return;
        setPdfBlob(null);
        clearElement(pagesRef.current);
        setErrorMessage(error instanceof Error ? error.message : "Не удалось загрузить PDF-рапорт за день.");
      } finally {
        if (isMounted) {
          setIsLoading(false);
        }
      }
    };

    void loadReportPdf();

    return () => {
      isMounted = false;
    };
  }, [departmentId, date]);

  useEffect(() => {
    if (!pdfBlob || !pagesRef.current) return undefined;

    let isCancelled = false;
    let loadingTask: any = null;
    const renderedCanvases: HTMLCanvasElement[] = [];

    const renderPdf = async () => {
      try {
        clearElement(pagesRef.current);

        const pdfjsLib = await getPdfJs();
        const pdfData = new Uint8Array(await pdfBlob.arrayBuffer());
        loadingTask = pdfjsLib.getDocument({ data: pdfData });
        const pdfDocument = await loadingTask.promise;

        for (let pageNumber = 1; pageNumber <= pdfDocument.numPages; pageNumber += 1) {
          if (isCancelled || !pagesRef.current) return;

          const page = await pdfDocument.getPage(pageNumber);
          const baseViewport = page.getViewport({ scale: 1 });
          const containerWidth = Math.max(pagesRef.current.clientWidth - 32, 320);
          const scale = Math.min(1.6, Math.max(0.7, containerWidth / baseViewport.width));
          const viewport = page.getViewport({ scale });

          const pageWrapper = document.createElement("div");
          pageWrapper.className = "report-pdf-page";

          const canvas = document.createElement("canvas");
          canvas.width = Math.floor(viewport.width);
          canvas.height = Math.floor(viewport.height);
          canvas.setAttribute("aria-label", `Страница ${pageNumber} PDF-рапорта`);

          const context = canvas.getContext("2d");
          if (!context) {
            throw new Error("Не удалось подготовить область просмотра PDF.");
          }

          pageWrapper.appendChild(canvas);
          pagesRef.current.appendChild(pageWrapper);
          renderedCanvases.push(canvas);

          await page.render({ canvasContext: context, viewport }).promise;
        }
      } catch (error) {
        if (isCancelled) return;
        clearElement(pagesRef.current);
        setErrorMessage(error instanceof Error ? error.message : "Не удалось отобразить PDF-рапорт на странице.");
      }
    };

    void renderPdf();

    return () => {
      isCancelled = true;
      if (loadingTask?.destroy) {
        void loadingTask.destroy();
      }
      renderedCanvases.forEach((canvas) => {
        canvas.width = 0;
        canvas.height = 0;
      });
      clearElement(pagesRef.current);
    };
  }, [pdfBlob]);

  const handleDownload = (): void => {
    if (!pdfBlob) return;

    const objectUrl = URL.createObjectURL(pdfBlob);
    const link = document.createElement("a");
    link.href = objectUrl;
    link.download = `daily-report-${date}.pdf`;
    document.body.appendChild(link);
    link.click();
    link.remove();
    window.setTimeout(() => URL.revokeObjectURL(objectUrl), 0);
  };

  const handlePrint = (): void => {
    window.print();
  };

  return (
    <div className="reports-page report-view-page">
      <div className="report-view-toolbar">
        <div className="report-view-toolbar__left">
          <button type="button" className="btn btn--ghost" onClick={() => navigate("/reports")}>Назад</button>
          <div>
            <h1 className="ui-page__title">Рапорт за день</h1>
            <p className="ui-page__text report-view-toolbar__subtitle">
              {formatRussianDate(date)} · {departmentName}
            </p>
          </div>
        </div>

        <div className="report-view-toolbar__actions">
          <button type="button" className="btn btn--ghost report-view-download" onClick={handleDownload} disabled={!pdfBlob}>
            <SvgIcon name="paper" />
            <span>Скачать PDF</span>
          </button>
          <button type="button" className="btn btn--info report-view-print" onClick={handlePrint} disabled={isLoading || !pdfBlob}>
            <SvgIcon name="print" />
            <span>Печать</span>
          </button>
        </div>
      </div>

      <div className="ui-divider report-view-no-print" />

      {errorMessage ? (
        <div className="ui-card ui-card__body reports-error-card report-view-no-print">
          <div className="reports-error-card__content">
            <span>{errorMessage}</span>
            <button type="button" className="btn btn--ghost" onClick={() => navigate("/reports")}>К списку рапортов</button>
          </div>
        </div>
      ) : null}

      {isLoading ? (
        <div className="ui-card ui-card__body reports-empty-card">Загрузка PDF-рапорта...</div>
      ) : pdfBlob ? (
        <section className="ui-card report-document-card report-pdf-card" aria-label="Просмотр PDF-рапорта">
          <div ref={pagesRef} className="report-pdf-pages" />
        </section>
      ) : null}
    </div>
  );
}
