import React, { useState } from 'react';
import { FiltersPanel, FiltersState } from '../components/FiltersPanel';
import { ResultsList, ReportRow } from '../components/ResultsList';
import './weather.css';

const DEFAULT_FILTERS: FiltersState = {
  windMetrics: new Set(['gust']), // 'gust' | 'sustained'
  minSeverity: 1,
  windowHours: 24,
  crewRec: 1, // optional, keep if you use it
};

export default function WeatherCenter() {
  const [filters, setFilters] = useState<FiltersState>(DEFAULT_FILTERS);
  const [rows, setRows] = useState<ReportRow[]>([]);
  const [isLoading, setIsLoading] = useState(false);

  async function runReport() {
    setIsLoading(true);
    try {
      // Replace this with your API.
      // Example GET /api/weather/report?wind=gust,sustained&minSeverity=3&window=48
      const data = await fakeFetch(filters); // see stub below
      setRows(data);
    } finally {
      setIsLoading(false);
    }
  }

  function exportCsv() {
    // Hook up to your existing export service; this is here to preserve the button.
    window.location.href = `/api/weather/export?minSeverity=${filters.minSeverity}&window=${filters.windowHours}`;
  }

  return (
    <div className="weather-center">
      <header className="wc-header">
        <h1 className="wc-title">Weather Center</h1>
        <div className="wc-actions">
          <button className="btn secondary" onClick={exportCsv}>Export CSV</button>
          <button className="btn primary" onClick={runReport} disabled={isLoading}>
            {isLoading ? 'Running…' : 'Run Report'}
          </button>
        </div>
      </header>

      {/* Filters are on the page, no modal */}
      <FiltersPanel value={filters} onChange={setFilters} />

      {/* Results populate in place, color-coded by severity */}
      <ResultsList rows={rows} emptyState={!isLoading && rows.length === 0} />
    </div>
  );
}

/** ----- Remove once you wire your API ----- */
async function fakeFetch(filters: FiltersState): Promise<ReportRow[]> {
  await new Promise(r => setTimeout(r, 600));
  return [
    { id: 'miami-dade', name: 'Miami-Dade, FL', gust: 30, sustained: 21, severity: 1, crewRec: 1 },
    { id: 'cook-il', name: 'Cook, IL', gust: 27, sustained: 17, severity: 1, crewRec: 1 },
    { id: 'nyc-ny', name: 'New York, NY', gust: 24, sustained: 14, severity: 1, crewRec: 1 },
  ].filter(r => r.severity >= filters.minSeverity);
}