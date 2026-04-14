# 🏪 Macrotienda — SQL Server Database Project

A complete SQL Server database project developed as part of the **SQL 360 course**, covering the full data engineering lifecycle: from database architecture and ETL to business analysis, optimization, and cloud fundamentals.

---

## 📋 Project Overview

**Macrotienda** is a fictional retail company operating across 4 markets (Spain, Brazil, Mexico, and the United States). This project models its transactional database using a **Star Schema** design, loads real data from CSV files, and performs comprehensive business analysis using advanced SQL techniques.

**Tech Stack:** Microsoft SQL Server · T-SQL · Google BigQuery (conceptual)

---

## 📁 Repository Structure

```
macrotienda-sql360/
│
├── scripts/                        # SQL scripts (execution order: 01 → 07)
│   ├── 01_Macrotienda_DB.sql           # Database creation, schema, tables and FK constraints
│   ├── 02_Macrotienda_Insercion.sql    # ETL pipeline: staging, transformation and load
│   ├── 03_Macrotienda_Analisis_Negocio.sql  # 9 business analysis queries
│   ├── 04_Macrotienda_Optimizacion_Vistas.sql  # Index optimization + 5 business views
│   ├── 05_Macrotienda_UDFs.sql         # 4 user-defined scalar functions
│   ├── 06_Macrotienda_Store_Procedures.sql  # 3 stored procedures
│   └── 07_Macrotienda_Triggers.sql     # Audit triggers + audit table
│
├── docs/
│   └── Macrotienda_Documentacion_Completa_v5.docx  # Full technical documentation
│
├── data/
│   ├── Ventas.csv                  # Raw sales data (source for ETL)
│   └── Productos.csv               # Product catalog with stock values
│
├── class-materials/                # Course slides and reference materials
│
└── README.md
```

---

## 🗄️ Database Architecture

The model follows a **Star Schema** pattern with 7 tables across the `Prod` schema:

| Table | Type | Description |
|-------|------|-------------|
| `Prod.Transacciones` | Fact | Main fact table — sales line detail |
| `Prod.Facturas` | Dimension | Invoice header — links client, vendor and region |
| `Prod.Productos` | Dimension | Product catalog with stock |
| `Prod.Clientes` | Dimension | Customer master data |
| `Prod.Vendedores` | Dimension | Sales team |
| `Prod.Marcas` | Dimension | Brand/supplier with geolocation |
| `Prod.Mercados` | Dimension | Commercial regions |

---

## 🔄 ETL Pipeline (Script 02)

The insertion script handles a **dirty CSV** file with the following transformations:

- Staging via `BULK INSERT` into temporary tables (all `VARCHAR`)
- Data cleaning: `TRIM`, `NULLIF`, decimal separator normalization (`,` → `.`)
- Type conversion using `TRY_CAST` and `TRY_CONVERT`
- Market normalization: `"Brazil"` → `"Brasil"`
- Load order following Star Schema dependencies (dimensions before facts)
- Idempotent inserts using `NOT EXISTS`
- Full `TRY/CATCH` transaction with integrity validation

---

## 📊 Business Analysis (Script 03)

9 business queries covering:

1. Product profit margin — with `NULLIF` to prevent division by zero
2. Inventory cost by brand — corrected granularity using independent subqueries
3. Monthly gross profit — first 3 months of 2016
4. Gross margin by supplier (brand)
5. Comparative analysis by market with window function `SUM() OVER()`
6. Vendor commercial activity with `HAVING` filter (>50 invoices)
7. Customer segmentation using chained CTEs (PREMIUM / STANDARD / New)
8. Day-by-day analysis with `LAG` — optimized with intermediate CTE to calculate LAG only once
9. Vendor ranking with `ROW_NUMBER()` and cumulative Pareto percentage

---

## ⚡ Optimization & Views (Script 04)

**5 covering indexes** created with `INCLUDE` columns:
- `idx_Facturas_Fecha_Venta`
- `idx_Facturas_ID_Region`
- `idx_Facturas_ID_Vendedor`
- `idx_Transacciones_ID_Factura`
- `idx_Transacciones_ID_Producto`

**5 business views** designed as a semantic layer for Power BI / end users:
- `V_Rentabilidad_Producto` — product profitability
- `V_Ventas_Por_Mercado` — KPIs by market
- `V_Performance_Vendedores` — vendor performance metrics
- `V_Segmentacion_Clientes` — customer segmentation detail
- `V_Inventario_Por_Marca` — inventory valuation by brand (v2: refactored with CTEs)

---

## ⚙️ User-Defined Functions (Script 05)

| Function | Parameters | Returns |
|----------|-----------|---------|
| `fn_Margen_Por_Transaccion` | `@ID_Producto`, `@ID_Transaccion` | `DECIMAL` — net profit of a sales line |
| `fn_Edad_Vendedor` | `@ID_Vendedor` | `INT` — current age in years |
| `fn_Disponibilidad_Stock` | `@ID_Marca`, `@Stock_Minimo` | `VARCHAR` — 'Suficiente' / 'Crítico' |
| `fn_Ticket_Promedio_Cliente` | `@ID_Cliente` | `DECIMAL` — average ticket per client |

---

## 🔧 Stored Procedures (Script 06)

| Procedure | Description |
|-----------|-------------|
| `sp_Actualizar_Precios_Por_Marca` | Mass price update by brand with transaction control |
| `sp_Reporte_Rendimiento_Mercado` | Market performance report + top vendor |
| `sp_Baja_Producto_Con_Validacion` | Safe product deletion with historical validation |

All procedures implement `TRY/CATCH`, `BEGIN TRANSACTION / COMMIT / ROLLBACK` and `SET NOCOUNT ON`.

---

## 🔴 Triggers (Script 07)

| Trigger | Type | Description |
|---------|------|-------------|
| `trg_Auditoria_Eliminacion_Producto` | `AFTER DELETE` | Logs every deletion to `Prod.Auditoria` |
| `trg_Bloqueo_Eliminacion_Por_Stock` | `INSTEAD OF DELETE` | Blocks deletion if product has stock > 0 |

---

## 📄 Documentation

Full technical documentation available in `/docs/`, including:
- Data dictionary for all 7 tables
- Entity-Relationship Diagram (DER)
- Business analysis query explanations
- Index optimization results
- Version history

---

## 🗂️ Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | Feb 2026 | Initial release |
| 2.0 | Apr 2026 | Query 1: NULLIF fix · Query 8: LAG optimization · View 5: CTE refactor |

---

## 👤 Author

**Marcelo López** — Data Analyst → Data Engineer  
[LinkedIn](https://www.linkedin.com/in/marceloflopez) · [GitHub](https://github.com/MLopezCastro)

*Course: SQL 360 · Instructor: Flavio Bevilacqua*
