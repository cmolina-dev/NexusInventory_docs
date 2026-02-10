# Documento de Arquitectura
# Proyecto: Stocky
# Sistema Híbrido Cloud-Edge con Sincronización Robusta

### 1. Introducción
Este documento describe la arquitectura técnica de Stocky, detallando las decisiones de diseño, tecnologías seleccionadas, patrones arquitectónicos y protocolos de comunicación que implementan los requerimientos funcionales definidos previamente.

Decisión arquitectónica fundamental: Rechazamos la arquitectura web-only con IndexedDB debido a sus limitaciones críticas (volatilidad, falta de garantías de persistencia, sincronización compleja entre cajas). En su lugar, implementamos una arquitectura híbrida con aplicaciones de escritorio nativas (Electron/Tauri) que utilizan SQLite como base de datos local.

Objetivo: Servir como guía técnica para la implementación, documentando el 'cómo' detrás del 'qué'.

### 2. Principios Arquitectónicos Fundamentales

#### 2.1 Hybrid Cloud-Edge Architecture
Combinamos lo mejor de ambos mundos:

    • Edge Computing: Cada punto de venta tiene poder computacional completo con base de datos SQL real
    • Cloud Coordination: Backend centralizado actúa como fuente de verdad y coordinador
    • Offline-First: Operaciones críticas nunca dependen de internet
    • Eventual Consistency: Sincronización robusta con resolución de conflictos

#### 2.2 La Nube como Fuente de Verdad
Decisión crítica: La nube SÍ es la fuente de verdad global. Esto simplifica enormemente la arquitectura:

    • Resolución de conflictos clara: Last-Write-Wins con timestamp del servidor
    • Auditabilidad: Todo cambio eventualmente llega a la nube para trazabilidad completa
    • Reportes confiables: Datos consolidados son autoritativos
    • Backup centralizado: La nube tiene el estado completo de todos los tenants

Las sedes NO compiten con la nube:

    • Sedes tienen autonomía operativa (pueden operar indefinidamente offline)
    • Pero cuando sincronizan, la nube tiene la última palabra en conflictos ambiguos
    • Para transacciones (ventas), no hay conflictos: modelo append-only

#### 2.3 Sincronización Robusta
Rechazamos modelos ingenuos (polling cada X segundos) a favor de:

    • Event-driven: Cambios en SQLite local disparan eventos de sincronización
    • Queue-based: Cola persistente con retry exponential backoff
    • Bidirectional: Push (local→nube) y Pull (nube→local)
    • Transactional: Batch de operaciones se envía como unidad atómica
    • Conflict detection: Vector clocks o timestamps del servidor

### 3. Stack Tecnológico Completo

#### 3.1 Aplicación Local (Desktop App)
Componente | Tecnología | Justificación
--- | --- | ---
Desktop Framework | Tauri/Electron | Rust backend (~3MB binary vs 100MB Electron), WebView nativo, mejor performance, menor consumo de recursos. Fallback: Electron si se necesitan features específicas
UI Framework | React 18 + TypeScript | Interfaz web servida localmente, reutilizable entre desktop y web admin
Build Tool | Vite | Build rápido, HMR eficiente durante desarrollo
Base de Datos Local | SQLite 3.45+ con WAL mode | Base de datos SQL completa, ACID, persistencia garantizada, sin límites prácticos, ~1MB library
ORM Local | Drizzle ORM o SQL.js | Type-safe queries, migraciones automáticas, funciona con SQLite
State Management | Zustand + TanStack Query | Zustand para UI state, React Query para data fetching y caché
Componentes UI | Shadcn/ui + Tailwind CSS | Componentes accesibles, customizables, consistencia entre desktop y web
HTTP Client | Axios o Tauri HTTP plugin | Para sincronización con backend, retry logic incluido

#### 3.2 Backend (Cloud API)
Componente | Tecnología | Justificación
--- | --- | ---
Runtime | Node.js 20 LTS + TypeScript | Ecosistema maduro, async/await nativo, TypeScript end-to-end
Framework API | NestJS | Arquitectura modular, DI nativo, WebSocket integrado, TypeScript-first
ORM | Prisma | Type-safe queries, migraciones automáticas, multi-tenant support
Autenticación | JWT + Passport.js | Stateless auth, tokens funcionan offline en cliente después de login inicial
Real-time | Socket.io | WebSocket con fallbacks, reconexión automática, rooms para multi-tenant y multi-sede
IA (Normalizer) | OpenAI API (GPT-4o) | LLM para normalización de catálogo, categorización, deduplicación
Message Queue | BullMQ + Redis | Jobs asíncronos (transferencias, sincronizaciones pesadas), retry logic, scheduling

#### 3.3 Infraestructura
Componente | Tecnología | Justificación
--- | --- | ---
Base de Datos | PostgreSQL 16+ | ACID, JSON support, partitioning por tenant, full-text search
Cache | Redis 7 | Caché de inventario consolidado, pub/sub para WebSocket, sesiones
Object Storage | AWS S3 / Cloudflare R2 | Imágenes de productos, backups de SQLite, instaladores de la app
Hosting Backend | Railway / Render / AWS | PostgreSQL managed, auto-scaling, CI/CD
Hosting Web Admin | Vercel / Netlify | Edge CDN, deploy automático desde Git
CDN para Instaladores | Cloudflare R2 + CDN | Distribución global de instaladores (.exe, .dmg, .AppImage)

### 4. Arquitectura de la Aplicación Local (Desktop App)

#### 4.1 Base de Datos SQLite
Cada sede tiene una base de datos SQLite completa con todo su inventario.

Schema SQLite (Tablas Principales):

    • app_config: Configuración de la aplicación
    • sede_info: Información de la sede y tenant
    • users: Usuarios sincronizados desde la nube
    • products: Catálogo maestro con versionado (version, last_modified_at)
    • inventory: Stock por sede con cantidad y umbrales
    • transactions: Registro append-only de todas las operaciones
    • sync_queue: Cola de operaciones pendientes de sincronizar
    • auth_session: Sesión de autenticación local
    • audit_logs: Logs de auditoría local

Configuración SQLite:

    • PRAGMA journal_mode = WAL: Write-Ahead Logging para concurrencia
    • PRAGMA synchronous = NORMAL: Balance entre performance y durabilidad
    • PRAGMA foreign_keys = ON: Integridad referencial
    • PRAGMA auto_vacuum = INCREMENTAL: Gestión automática de espacio

Por qué SQLite en lugar de IndexedDB:

Aspecto | SQLite | IndexedDB
--- | --- | ---
Persistencia | ✅ Garantizada por el SO | ⚠️ Volátil, navegador puede borrar
Límites de tamaño | ✅ Ilimitado (GB, TB) | ⚠️ ~50-100MB recomendado
Performance | ✅ Extremadamente rápido | ⚠️ Más lento para queries complejas
Queries | ✅ SQL completo (JOIN, GROUP BY, etc.) | ⚠️ Limitado (solo índices, no joins)
Transacciones ACID | ✅ Completas | ⚠️ Limitadas
Concurrencia | ✅ WAL mode permite lecturas concurrentes | ⚠️ Single-writer
Backup | ✅ Copiar archivo .db | ⚠️ Complejo (exportar/importar)
Confiabilidad | ✅ Probado en producción por décadas | ⚠️ Bugs dependiendo del navegador

**IMPORTANTE - Diferencias entre SQLite (Local) y PostgreSQL (Nube):**

Las tablas en SQLite y PostgreSQL NO son idénticas. Aunque comparten entidades similares (products, inventory, transactions), tienen diferencias clave:

SQLite (Aplicación Local):

    • Optimizado para operaciones locales de una sede específica
    • Solo contiene datos de UNA sede y su tenant
    • Campos adicionales para sincronización: synced_at, version
    • Tabla sync_queue para gestionar cambios pendientes
    • Tabla auth_session para sesión local
    • NO tiene campos como is_online, last_ping_at (esos son del backend)

PostgreSQL (Backend/Nube):

    • Fuente de verdad global para TODOS los tenants
    • Contiene datos de TODAS las sedes
    • Campos adicionales para coordinación: is_online, last_ping_at, sync_version
    • Tablas adicionales: activation_codes, sync_logs
    • Campos de auditoría más completos: last_modified_by, before_data, after_data
    • Timestamps duales: client_timestamp vs server_timestamp

Ejemplo de diferencias en la tabla products:

```
SQLite (Local):
- id, sku, name, price, cost, version, last_modified_at, synced_at

PostgreSQL (Nube):
- id, sku, name, price, cost, version, last_modified_at, last_modified_by, 
  tenant_id, barcode, metadata, created_at, updated_at
```

Ver ERD_Hub_v2.md para el schema completo de PostgreSQL.

#### 4.2 Motor de Sincronización
Componentes:

1. Network Monitor: Monitorea conectividad con ping periódico al backend
2. Push Worker: Procesa sync_queue y envía cambios en batches con retry exponencial backoff
3. Pull Worker: Polling cada 5min + WebSocket listener para cambios en tiempo real
4. Conflict Resolver: Last-Write-Wins basado en timestamp del servidor

Protocolo de Sincronización:

Push (Cliente → Backend):
1. Detecta conexión, lee sync_queue con status=PENDING
2. Agrupa en lotes de 50 operaciones
3. POST /api/sync/push con { sedeId, operations: [...] }
4. Backend valida, aplica, responde con confirmación
5. Cliente marca status=SYNCED

Pull (Backend → Cliente):
1. POST /api/sync/pull con lastPullTimestamp
2. Backend responde con cambios desde timestamp
3. Cliente aplica con INSERT OR REPLACE
4. Actualiza lastPullTimestamp

#### 4.3 Sincronización Multi-Caja via LAN
Para sedes con múltiples cajas (computadores), implementamos sincronización local via WebSocket.

Arquitectura:

    • Caja 1 (Master): Servidor WebSocket local en puerto 3001
    • Caja 2, 3... (Slaves): Clientes WebSocket conectados a Caja 1
    • Cambios se propagan en tiempo real (< 1s) entre cajas
    • Solo Caja Master sincroniza con la nube
    • Failover automático si Caja Master cae

### 5. Arquitectura del Backend

#### 5.1 Módulos NestJS

- AuthModule: JWT + Passport, RBAC guards, tenant isolation middleware <br>
- SyncModule: Endpoints /sync/push y /sync/pull, validación, detección de conflictos <br>
- TransferModule: POST /transfers/request, /approve, /reject. Coordina operación atómica vía BullMQ <br>
- InventoryModule: GET /inventory/consolidated, usa Redis para cachear agregaciones <br>
- AIModule: POST /ai/normalize con OpenAI GPT-4o, rate limiting, caché de resultados <br>
- AuditModule: Interceptor global, almacena todos los logs en PostgreSQL <br>
- SocketGateway: WebSocket con rooms por tenant y sede, notificaciones en tiempo real

#### 5.2 Modelo de Datos PostgreSQL
El backend almacena vistas consolidadas y actúa como fuente de verdad:

    • tenants: id, name, plan, status, createdAt
    • sedes: id, tenantId, name, address, isOnline, lastPingAt, lastSyncAt, syncVersion
    • activation_codes: id, sedeId, code, usedAt (nuevo para activación de apps)
    • users: id, tenantId, sedeId, email, passwordHash, role
    • products: id, tenantId, sku, name, category, price, cost, version, lastModifiedAt, lastModifiedBy
    • inventory: id, tenantId, sedeId, productId, quantity, minStock, maxStock, lastUpdatedAt
    • transactions: id, tenantId, sedeId, productId, type, quantity, price, userId, clientTimestamp, serverTimestamp, syncedAt
    • transfers: id, tenantId, fromSedeId, toSedeId, productId, quantity, status, requestedBy, approvedBy, createdAt, completedAt
    • audit_logs: id, tenantId, userId, action, entityType, entityId, metadata (JSONB), timestamp
    • sync_logs: id, sedeId, operation, itemsCount, status, duration, timestamp (nuevo para monitoreo)

Nota: El esquema completo con diagramas ERD, constraints, índices y triggers está documentado en ERD_Hub_v2.md

#### 5.3 Protocolo de Transferencias
Fase 1 - Solicitud:

    • Frontend valida ambas sedes online
    • POST /transfers/request
    • Backend crea registro status=PENDING

Fase 2 - Aprobación:

    • Notifica sede origen vía WebSocket
    • Store Manager valida stock local
    • POST /transfers/:id/approve o /reject

Fase 3 - Ejecución Atómica:

    • Backend status=PROCESSING, crea job en BullMQ
    • Worker ejecuta transacción en PostgreSQL
    • Envía WebSocket a ambas sedes: TRANSFER_OUT y TRANSFER_IN
    • Sedes actualizan SQLite local
    • Backend status=COMPLETED, invalida caché Redis

### 6. Decisiones Técnicas Clave

#### 6.1 Por qué Tauri/Electron sobre PWA
Tauri/Electron:

    • ✅ SQLite garantiza persistencia
    • ✅ Multi-caja sincronizada via LAN
    • ✅ Sin límites de almacenamiento
    • ✅ SQL completo para queries complejas
    • ✅ Backup simple (copiar archivo .db)
    • ⚠️ Requiere instalación one-time

PWA + IndexedDB (rechazado):

    • ⚠️ IndexedDB puede ser borrado por el navegador
    • ⚠️ Límites de ~50-100MB
    • ❌ Imposible sincronizar múltiples cajas sin internet
    • ⚠️ Queries limitadas

#### 6.2 PostgreSQL + Redis vs MongoDB
Decisión: PostgreSQL + Redis

    • ACID garantizado para transferencias
    • Relaciones explícitas, agregaciones SQL eficientes
    • Redis para caché de inventario consolidado
    • Row-Level Security para multi-tenancy

#### 6.3 Consistencia Híbrida
Eventual para operaciones locales:

    • Ventas, entradas, ajustes se ejecutan localmente, sincronizan después

Fuerte para transferencias inter-sede:

    • Requiere ambas sedes online, validación en tiempo real, ejecución atómica
    • Justificación: Operaciones locales no afectan otras sedes, transferencias sí requieren coordinación

#### 6.4 Resolución de Conflictos
Estrategias por tipo de entidad:

Productos (campos editables):

    • Last-Write-Wins basado en version y timestamp del servidor
    • Si remote.version > local.version → Cloud wins
    • Si versiones iguales, timestamp del servidor decide

Transacciones:

    • Append-only (sin conflictos)
    • Cada transacción tiene UUID único
    • Backend hace INSERT con skipDuplicates

Inventario:

    • Cloud-wins para cantidad absoluta
    • Pero se recalcula desde transacciones si hay discrepancia

Configuraciones (usuarios, roles):

    • Cloud-wins (siempre)
    • No se modifican localmente

### 7. Seguridad Multi-Tenant

#### 7.1 Aislamiento de Datos
    • PostgreSQL: Row-Level Security policies, tenantId en todas las tablas
    • Prisma middleware inyecta tenantId automáticamente
    • NestJS TenantGuard valida user.tenantId === resource.tenantId
    • SQLite local: Solo datos del tenant y sede correspondiente

#### 7.2 Autenticación
    • JWT Structure: { userId, tenantId, sedeId, role, exp }
    • RBAC con decoradores @Roles(['ADMIN', 'MANAGER'])
    • Tokens funcionan offline, validación local con firma verificada
    • Auto-logout después de 8 horas de inactividad

#### 7.3 Protección de Datos Locales
    • SQLite puede encriptarse con SQLCipher (opcional)
    • Sesión JWT almacenada de forma segura
    • HTTPS/TLS para todas las conexiones al backend
    • WebSocket sobre WSS (seguro)

### 8. Distribución de la Aplicación

#### 8.1 Generación de Instaladores
Tauri:

    • Windows: .exe con auto-updater
    • macOS: .dmg firmado
    • Linux: .AppImage, .deb

Configuración de Auto-Update:

    • La app verifica actualizaciones al iniciar (si hay internet)
    • Descarga updates en background
    • Notifica al usuario y solicita reinicio
    • Rollback automático si la actualización falla

#### 8.2 Flujo de Activación
1. Tenant Admin crea sede desde web admin
2. Backend genera código de activación único (6 dígitos)
3. Admin descarga instalador genérico
4. Instala en el punto de venta
5. Al abrir app por primera vez, solicita código de activación
6. App envía código al backend: POST /activate
7. Backend valida código, retorna: sede_id, tenant_id, JWT token, configuración inicial
8. App descarga catálogo inicial a SQLite
9. App queda activada y lista para operar

### 9. Conclusión
Esta arquitectura combina autonomía local con coordinación centralizada para operaciones inter-sede. Cada decisión técnica prioriza:

    • Confiabilidad y persistencia garantizada sobre facilidad de distribución
    • Sincronización robusta con resolución de conflictos clara
    • Herramientas profesionales probadas sobre implementaciones desde cero

El stack seleccionado (Tauri + SQLite + NestJS + PostgreSQL + Redis) balancea madurez tecnológica, type safety end-to-end, y flexibilidad para casos de uso complejos como transferencias atómicas entre sedes.

Comparación con arquitectura anterior:

Aspecto | Web-only + IndexedDB | Hybrid + SQLite
--- | --- | ---
Persistencia | ⚠️ Volátil | ✅ Garantizada
Multi-caja (LAN) | ❌ Imposible | ✅ Tiempo real
Queries | ⚠️ Limitado | ✅ SQL completo
Instalación | ✅ Cero | ⚠️ One-time
Confiabilidad | ⚠️ Riesgosa | ✅ Extrema

Este documento define el 'cómo' técnico. Los detalles de implementación específicos (schemas completos, algoritmos de replication, configuraciones de deployment) se documentarán en READMEs técnicos del repositorio.
