# Documento de Arquitectura
# Proyecto: Stocky
# Sistema Distribuido Multi-Sede Offline-First

### 1. Introducción
Este documento describe la arquitectura técnica de Stocky, detallando las decisiones de diseño, tecnologías seleccionadas, patrones arquitectónicos y protocolos de comunicación que implementan los requerimientos funcionales definidos previamente.
Objetivo: Servir como guía técnica para la implementación, documentando el 'cómo' detrás del 'qué'.

### 2. Principios Arquitectónicos Fundamentales

#### 2.1 Offline-First
Cada sede debe poder operar de forma completamente autónoma sin depender de conectividad. La aplicación web trata el estado offline como el caso normal, no como una excepción.
Implicaciones técnicas:

    • Base de datos completa y funcional en el cliente (IndexedDB)
    • Lógica de negocio crítica ejecuta localmente
    • Sincronización eventual como proceso en segundo plano
#### 2.2 Autonomía de Sede
Cada sede es dueña de su inventario físico y de sus datos. No existe inventario compartido; las transferencias entre sedes son operaciones explícitas y atómicas.
Implicaciones técnicas:

    • Base de datos local completa por sede (no caché)
    • Transacciones son append-only por sede
    • Transferencias requieren coordinación entre backend y ambas sedes
#### 2.3 Backend como Hub Coordinador
El backend agrega información y coordina operaciones inter-sede, pero no es la fuente única de verdad para el inventario local.
Implicaciones técnicas:

    • Backend almacena vistas consolidadas (reportes)
    • Sedes sincronizan para visibilidad, no para validación
### 3. Stack Tecnológico Completo

#### 3.1 Frontend (Cliente/Sede)
Componente	Tecnología	Justificación
Framework UI	React 18 + TypeScript	Ecosistema maduro, hooks para reactive queries, TypeScript para type safety
Build Tool	Vite	Build rápido, HMR eficiente, PWA plugins nativos
Base de Datos Local	RxDB 15.x sobre IndexedDB	Reactive queries, replication flexible, TypeScript schemas, multi-tab sync
State Management	Zustand + RxJS	Zustand para UI state, RxJS para streams reactivos de RxDB
Componentes UI	Shadcn/ui + Tailwind CSS	Componentes accesibles, customizables, utility-first CSS
PWA	Vite PWA Plugin (Workbox)	Service Worker automático, caché de assets, instalable

#### 3.2 Backend (API)
Componente	Tecnología	Justificación
Runtime	Node.js 20 LTS + TypeScript	Ecosistema JavaScript completo, async/await nativo, TypeScript end-to-end
Framework API	NestJS	Arquitectura modular, DI nativo, WebSocket integrado, TypeScript-first
ORM	Prisma	Type-safe queries, migraciones automáticas, multi-tenant support
Autenticación	JWT + Passport.js	Stateless auth, funciona offline con tokens en cliente
Real-time	Socket.io	WebSocket con fallbacks, reconexión automática, rooms para multi-tenant
IA (Normalizer)	OpenAI API (GPT-4)	LLM para normalización de nombres, categorización, deduplicación

#### 3.3 Infraestructura
Componente	Tecnología	Justificación
Base de Datos	PostgreSQL 16	ACID, JSON support, partitioning para multi-tenant
Cache	Redis 7	Inventario consolidado en caché, sesiones, pub/sub para WebSocket
Message Queue	BullMQ	Jobs asíncronos (transferencias), retry logic, scheduling
Object Storage	AWS S3 / Cloudflare R2	Imágenes de productos, importaciones CSV/Excel, backups
Hosting	Railway (Backend) + Vercel (Frontend)	Deploy automático, Postgres managed, Edge CDN para PWA

### 4. Arquitectura del Cliente (Sede)

#### 4.1 Base de Datos Local con RxDB
Cada sede mantiene una base de datos completa usando RxDB sobre IndexedDB. Esta NO es un caché; es la fuente de verdad para operaciones locales.

Colecciones RxDB

products: Catálogo de productos <br>
    Schema: id, sku, name, description, category, price, cost, sedeId, tenantId, lastModified, version

inventory: Stock actual <br>
    Schema: id, productId, quantity, minStock, maxStock, sedeId, lastUpdated

transactions: Log de transacciones (append-only) <br>
    Schema: id, type (IN/OUT/ADJUSTMENT), productId, quantity, reason, userId, sedeId, timestamp, synced

sync_queue: Cola de cambios pendientes <br>
    Schema: id, operation, collection, documentId, payload, timestamp, retries, status

auth_session: Autenticar la sesión <br>
    Schema: token, userId, tenantId, sedeId, role, expiresAt, lastRefresh

#### 4.2 Motor de Sincronización
Componentes:
1. Network Detector

    • Monitorea navigator.onLine y hace pings periódicos al backend
2. Change Observer

    • Observa cambios en RxDB y agrega a sync_queue
3. Replication Handler

    • Push: envía cambios locales en lotes
    • Pull: recibe actualizaciones del backend
4. Conflict Resolver

    • Last-Write-Wins basado en timestamp del servidor

Protocolo de Sincronización
Push (Cliente → Backend):
1. Detecta conexión, lee sync_queue con synced=false
2. Agrupa en lotes de 50 operaciones
3. POST /api/sync/push con { sedeId, operations: [...] }
4. Backend valida, aplica, responde con confirmación
5. Cliente marca synced=true

Pull (Backend → Cliente):
1. GET /api/sync/pull con lastPullTimestamp
2. Backend responde con cambios desde timestamp
3. Cliente aplica con .upsert()
4. Actualiza lastPullTimestamp

### 5. Arquitectura del Backend

#### 5.1 Módulos NestJS
AuthModule: JWT + Passport, RBAC guards, tenant isolation middleware <br>
SyncModule: Endpoints /sync/push y /sync/pull, validación, detección de conflictos <br>
TransferModule: POST /transfers/request, /approve, /reject. Coordina operación atómica vía BullMQ <br>
InventoryModule: GET /inventory/consolidated, usa Redis para cachear agregaciones <br>
AIModule: POST /ai/normalize con OpenAI GPT-4, rate limiting, caché de resultados <br>
AuditModule: Interceptor global, almacena todos los logs en PostgreSQL <br>

#### 5.2 Modelo de Datos PostgreSQL
El backend almacena vistas consolidadas, no el inventario operativo: 

    • tenants: id, name, plan, status, createdAt
    • sedes: id, tenantId, name, address, status, lastSyncAt
    • users: id, tenantId, sedeId, email, passwordHash, role
    • products_consolidated: id, tenantId, sku, name, category, version
    • inventory_consolidated: id, tenantId, sedeId, productId, quantity, lastSyncAt
    • transactions_log: id, tenantId, sedeId, productId, type, quantity, timestamp, syncedAt
    • transfers: id, tenantId, fromSedeId, toSedeId, productId, quantity, status, createdAt, completedAt
    • audit_logs: id, tenantId, userId, action, entityType, entityId, metadata (JSONB), timestamp

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
    • Sedes actualizan IndexedDB local
    • Backend status=COMPLETED, invalida caché Redis

### 6. Decisiones Técnicas Clave

#### 6.1 Por qué RxDB
RxDB 

    • ✅ Reactive queries con RxJS
    • ✅ Replication protocol flexible y customizable
    • ✅ TypeScript-first, schemas con Zod
    • ✅ Multi-tab sync nativo

#### 6.2 PostgreSQL + Redis vs MongoDB
Decisión: PostgreSQL + Redis
    • ACID garantizado para transferencias
    • Relaciones explícitas, agregaciones SQL eficientes
    • Redis para caché de inventario consolidado

#### 6.3 Consistencia Híbrida
Eventual para operaciones locales

    • Ventas, entradas, ajustes se ejecutan localmente, sincronizan después
Fuerte para transferencias inter-sede

    • Requiere ambas sedes online, validación en tiempo real, ejecución atómica
    • Justificación: Operaciones locales no afectan otras sedes, transferencias sí requieren coordinación

### 7. Seguridad Multi-Tenant

#### 7.1 Aislamiento de Datos

    • PostgreSQL: Row-Level Security policies, tenantId en todas las tablas
    • Prisma middleware inyecta tenantId automáticamente
    • NestJS TenantGuard valida user.tenantId === resource.tenantId

##### 7.2 Autenticación

    • JWT Structure: { userId, tenantId, sedeId, role, exp }
    • RBAC con decoradores @Roles(['ADMIN', 'MANAGER'])
    • Tokens funcionan offline, validación local con firma verificada

### 8. Conclusión
Esta arquitectura combina autonomía local con coordinación centralizada para operaciones inter-sede. Cada decisión técnica prioriza:

    • Operatividad sin internet sobre sincronización en tiempo real
    • Simplicidad operativa sobre disponibilidad total de funcionalidades offline
    • Herramientas profesionales probadas sobre implementaciones desde cero

El stack seleccionado (React + RxDB + NestJS + PostgreSQL + Redis) balancea madurez tecnológica, type safety end-to-end, y flexibilidad para casos de uso complejos como transferencias atómicas entre sedes.
Este documento define el 'cómo' técnico. Los detalles de implementación específicos (schemas completos, algoritmos de replication, configuraciones de deployment) se documentarán en READMEs técnicos del repositorio.