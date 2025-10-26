import React from 'react';

export type ReportRow = {
  id: string;
  name: string;
  gust: number;
  sustained: number;
  severity: 1 | 2 | 3 | 4 | 5;
  crewRec?: number;
};

export function ResultsList({ rows, emptyState }: { rows: ReportRow[]; emptyState: boolean }) {
  if (emptyState) {
    return <div className="empty">Run a report to see results.</div>;
  }
  return (
    <ul className="results">
      {rows.map(row => (
        <li key={row.id} className={`result severity-${row.severity}`} role="article" aria-label={`${row.name} severity ${row.severity}`}>
          <div className="result-main">
            <div className="result-name">{row.name}</div>
            <div className="result-meta">Gust: {row.gust} mph · Sustained: {row.sustained} mph</div>
          </div>
          <div className="result-side">
            <div className="sev-badge">Sev {row.severity}</div>
            {row.crewRec ? <div className="crew">{row.crewRec} crews</div> : null}
          </div>
        </li>
      ))}
    </ul>
  );
}