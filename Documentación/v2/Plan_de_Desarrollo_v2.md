# Plan de Desarrollo - Stocky v2
## Roadmap de Implementación (Arquitectura Híbrida)

**Proyecto:** Stocky  
**Versión:** 2.0 (Desktop Apps + SQLite)  
**Objetivo:** Sistema de inventario multi-tenant offline-first con aplicaciones de escritorio  
**Última actualización:** 2026-02-09

---

## Filosofía de Desarrollo

### Principios Clave

1. **Incremental y Funcional**: Cada fase debe resultar en algo funcional que puedas probar
2. **Offline-First desde el inicio**: No dejes la funcionalidad offline para el final
3. **Backend y Frontend en paralelo**: Desarrolla ambos simultáneamente para validar la integración temprano
4. **Testing continuo**: Prueba cada módulo antes de avanzar al siguiente
5. **Desktop-first**: Prioriza la aplicación de escritorio sobre la web admin

### Estrategia de Priorización

```
Prioridad 1: Funcionalidad CORE offline (operación local de una sede)
Prioridad 2: Sincronización robusta (push/pull con detección de conflictos)
Prioridad 3: Multi-tenant y coordinación inter-sede
Prioridad 4: Features avanzadas (IA, reportes complejos, LAN sync)
```

### Cambios respecto a v1

- **Desktop apps** (Tauri/Electron) en lugar de PWA
- **SQLite** en lugar de IndexedDB/RxDB
- **Códigos de activación** para instaladores
- **LAN sync** para múltiples cajas por sede
- **Sincronización más robusta** con detección de conflictos mejorada

---

## Fase 0: Setup Inicial (2-3 días)

### Backend

- [x] Inicializar proyecto NestJS con TypeScript
- [x] Configurar PostgreSQL local (Docker recomendado)
- [x] Configurar Redis local (Docker recomendado)
- [x] Setup Prisma ORM
- [x] Definir schema.prisma completo (basado en ERD_Hub_v2.md)
- [x] Ejecutar primera migración
- [x] Configurar variables de entorno (.env)
- [x] Setup ESLint y Prettier

### Desktop App (Local)

- [X] Inicializar proyecto Electron
- [X] Configurar React + Vite + TypeScript
- [X] Configurar Tailwind CSS
- [X] Instalar Shadcn/ui
- [ ] Configurar SQLite (better-sqlite3)
- [ ] Configurar estructura de carpetas
- [ ] Setup ESLint y Prettier
- [ ] Configurar hot reload para desarrollo

### Web Admin

- [ ] Inicializar proyecto Next.js (App Router)
- [ ] Configurar Tailwind CSS
- [ ] Instalar Shadcn/ui
- [ ] Setup ESLint y Prettier

### Infraestructura

- [ ] Crear repositorio Git (monorepo recomendado)
- [ ] Configurar .gitignore
- [ ] Documentar README con instrucciones de setup
- [ ] Configurar scripts de desarrollo (package.json)

**Entregable:** Proyectos inicializados, bases de datos corriendo, estructura básica lista

---

## Fase 1: Autenticación y Multi-Tenancy (3-4 días)

### Backend

- [ ] Implementar AuthModule (NestJS)
  - [ ] Registro de usuarios
  - [ ] Login con JWT
  - [ ] Refresh tokens
  - [ ] Guards de autenticación
- [ ] Implementar TenantModule
  - [ ] CRUD de tenants
  - [ ] CRUD de sedes
  - [ ] Middleware de tenant isolation
- [ ] Implementar ActivationCodeModule
  - [ ] Generar códigos de activación
  - [ ] POST /activate (validar código y retornar configuración)
- [ ] Configurar Row-Level Security en PostgreSQL
- [ ] Implementar RBAC (Role-Based Access Control)
  - [ ] Guards por rol
  - [ ] Decoradores @Roles()

### Desktop App

- [ ] Crear pantalla de activación (primera vez)
  - [ ] Input para código de 6 dígitos
  - [ ] Validar código con backend
  - [ ] Guardar configuración (sede_id, tenant_id)
- [ ] Crear pantalla de login
  - [ ] Email y contraseña
  - [ ] Guardar JWT en auth_session (SQLite)
- [ ] Implementar AuthContext/Store (Zustand)
- [ ] Configurar axios/fetch con interceptors para JWT
- [ ] Crear ProtectedRoute component
- [ ] Implementar tabla auth_session en SQLite

### Testing

- [ ] Activar app con código válido
- [ ] Login exitoso genera JWT válido
- [ ] JWT se guarda en SQLite
- [ ] Rutas protegidas redirigen si no hay sesión
- [ ] Roles se validan correctamente

**Entregable:** Sistema de activación y login funcional, usuarios pueden autenticarse

---

## Fase 2: Base de Datos Local (SQLite) (4-5 días)

### Desktop App

- [ ] Implementar schemas SQLite (basado en Schema_SQLite.md)
  - [ ] products
  - [ ] inventory
  - [ ] transactions
  - [ ] sync_queue
  - [ ] users
  - [ ] auth_session
  - [ ] config
- [ ] Crear función de inicialización de SQLite
- [ ] Configurar PRAGMA (WAL mode, foreign keys, etc.)
- [ ] Implementar migraciones de schema
- [ ] Crear hooks React para cada tabla
  - [ ] useProducts()
  - [ ] useInventory()
  - [ ] useTransactions()
- [ ] Implementar triggers SQLite
  - [ ] update_inventory_after_transaction
  - [ ] sync_product_on_update
- [ ] Crear utilidades para queries complejas

### Testing

- [ ] Crear productos en SQLite
- [ ] Consultar productos (individual y batch)
- [ ] Crear transacciones append-only
- [ ] Calcular stock desde transacciones
- [ ] Verificar que datos persisten al cerrar app
- [ ] Verificar triggers funcionan correctamente
- [ ] Probar queries con JOIN

**Entregable:** Base de datos SQLite funcional, operaciones CRUD offline, datos persisten

---

## Fase 3: Módulo de Productos e Inventario (Offline) (5-6 días)

### Desktop App

- [ ] Crear UI para gestión de productos
  - [ ] Lista de productos (tabla con búsqueda)
  - [ ] Crear producto
  - [ ] Editar producto
  - [ ] Eliminar producto (soft delete)
  - [ ] Búsqueda por SKU, nombre, código de barras
  - [ ] Filtros por categoría
- [ ] Crear UI para inventario
  - [ ] Vista de stock actual
  - [ ] Alertas de stock bajo
  - [ ] Ajustes manuales de inventario
- [ ] Implementar validaciones de formularios
- [ ] Agregar indicador visual de "Modo Offline"
- [ ] Implementar escaneo de código de barras (opcional)

### Lógica de Negocio

- [ ] Validar SKU único por tenant
- [ ] Calcular stock automáticamente desde transacciones
- [ ] Actualizar inventory cuando se crea una transacción
- [ ] Implementar control de versión para conflictos
- [ ] Agregar cambios a sync_queue

### Testing

- [ ] Crear 20 productos offline
- [ ] Editar productos y verificar versión incrementa
- [ ] Crear transacciones y verificar stock se actualiza
- [ ] Cerrar app y verificar datos persisten
- [ ] Simular pérdida de conexión (desconectar red)
- [ ] Verificar triggers actualizan inventory correctamente

**Entregable:** Gestión completa de productos e inventario funcionando 100% offline

---

## Fase 4: Módulo de Transacciones (POS Lite) (4-5 días)

### Desktop App

- [ ] Crear UI para registro de transacciones
  - [ ] Venta (SALE)
  - [ ] Entrada (PURCHASE)
  - [ ] Ajuste manual (ADJUSTMENT)
- [ ] Implementar carrito de compra simple
- [ ] Validar stock disponible antes de venta
- [ ] Crear historial de transacciones
- [ ] Implementar filtros por fecha, tipo, producto
- [ ] Agregar búsqueda rápida por código de barras

### Lógica de Negocio

- [ ] Validar stock antes de registrar venta
- [ ] Crear transacción append-only con UUID
- [ ] Actualizar inventory automáticamente (via trigger)
- [ ] Agregar transacción a sync_queue
- [ ] Implementar batch processing para ventas múltiples
- [ ] Guardar metadata (método de pago, cliente, etc.)

### Testing

- [ ] Registrar venta de 1 producto
- [ ] Registrar venta de 50 productos (validar rendimiento)
- [ ] Intentar vender más stock del disponible (debe fallar)
- [ ] Verificar historial muestra todas las transacciones
- [ ] Verificar transacciones se agregan a sync_queue
- [ ] Cerrar app y verificar datos persisten

**Entregable:** POS funcional offline, ventas y entradas de inventario operativas

---

## Fase 5: Backend - Endpoints de Sincronización (5-6 días)

### Backend

- [ ] Implementar SyncModule
  - [ ] POST /api/sync/push (recibir cambios del cliente)
  - [ ] POST /api/sync/pull (enviar cambios al cliente)
  - [ ] POST /api/sync/heartbeat (ping de conectividad)
- [ ] Implementar lógica de validación de cambios
- [ ] Guardar transacciones en transactions
- [ ] Actualizar inventory
- [ ] Actualizar products
- [ ] Implementar detección de conflictos
  - [ ] Comparar version y last_modified_at
  - [ ] Aplicar política Last-Write-Wins
- [ ] Crear logs de auditoría
- [ ] Crear logs de sincronización (sync_logs)

### Testing

- [ ] Push de 10 transacciones desde cliente
- [ ] Verificar datos en PostgreSQL
- [ ] Pull de productos desde backend
- [ ] Simular conflicto (mismo producto editado en 2 sedes)
- [ ] Verificar Last-Write-Wins funciona correctamente
- [ ] Verificar sync_logs se crean correctamente

**Entregable:** Backend puede recibir y enviar cambios, sincronización básica funcional

---

## Fase 6: Motor de Sincronización (Desktop App) (5-6 días)

### Desktop App

- [ ] Implementar Network Detector
  - [ ] Monitorear conectividad con ping periódico
  - [ ] Actualizar estado online/offline
- [ ] Implementar Sync Engine
  - [ ] Procesar sync_queue automáticamente
  - [ ] Push en lotes de 50 operaciones
  - [ ] Pull periódico (cada 5 minutos)
  - [ ] Retry logic con backoff exponencial
  - [ ] Marcar como FAILED después de 5 intentos
- [ ] Crear UI de estado de sincronización
  - [ ] Indicador online/offline
  - [ ] Contador de operaciones pendientes
  - [ ] Última sincronización exitosa
  - [ ] Progreso de sincronización
- [ ] Implementar sincronización manual (botón)
- [ ] Implementar resolución de conflictos
  - [ ] Aplicar cambios del servidor si version > local

### Testing

- [ ] Crear 20 transacciones offline
- [ ] Reconectar y verificar sincronización automática
- [ ] Verificar datos en PostgreSQL
- [ ] Desconectar durante sincronización (debe reintentar)
- [ ] Simular error de backend (debe marcar como FAILED)
- [ ] Editar mismo producto en 2 sedes (verificar conflicto)

**Entregable:** Sincronización automática funcional, datos fluyen entre cliente y backend

---

## Fase 7: Gestión de Sedes (3-4 días)

### Backend

- [ ] Implementar SedesModule
  - [ ] CRUD de sedes
  - [ ] Asignar usuarios a sedes
  - [ ] Actualizar last_sync_at, last_ping_at
  - [ ] Endpoint para listar sedes online/offline
  - [ ] Generar códigos de activación

### Web Admin (o Desktop App para Tenant Admin)

- [ ] Crear UI de administración de sedes
  - [ ] Lista de sedes con estado (online/offline)
  - [ ] Crear/editar sede
  - [ ] Generar código de activación
  - [ ] Ver estado de sincronización por sede
  - [ ] Asignar usuarios a sedes

### Testing

- [ ] Crear 3 sedes para un tenant
- [ ] Generar códigos de activación
- [ ] Activar apps en cada sede
- [ ] Asignar usuarios a cada sede
- [ ] Verificar aislamiento (Sede A no ve datos de Sede B)
- [ ] Verificar last_sync_at se actualiza correctamente

**Entregable:** Gestión de múltiples sedes, aislamiento de datos por sede

---

## Fase 8: Transferencias entre Sedes (7-8 días)

### Backend

- [ ] Implementar TransferModule
  - [ ] POST /transfers/request
  - [ ] POST /transfers/:id/approve
  - [ ] POST /transfers/:id/reject
  - [ ] GET /transfers (listar transferencias)
- [ ] Configurar BullMQ
- [ ] Crear TransferWorker
  - [ ] Validar stock en sede origen
  - [ ] Ejecutar transacción atómica
  - [ ] Crear TRANSFER_OUT y TRANSFER_IN
  - [ ] Actualizar inventory
  - [ ] Notificar vía WebSocket
- [ ] Implementar WebSocket Gateway (Socket.io)
  - [ ] Rooms por tenant y sede
  - [ ] Eventos de transferencia

### Desktop App

- [ ] Crear UI para solicitar transferencia
  - [ ] Seleccionar sede destino
  - [ ] Seleccionar producto
  - [ ] Especificar cantidad
  - [ ] Validar que ambas sedes estén online
- [ ] Crear UI para aprobar/rechazar transferencias
- [ ] Implementar WebSocket client
  - [ ] Escuchar eventos de transferencia
  - [ ] Actualizar SQLite local al recibir TRANSFER_IN/OUT
- [ ] Crear lista de transferencias pendientes

### Testing

- [ ] Solicitar transferencia de Sede A a Sede B
- [ ] Aprobar desde Sede B
- [ ] Verificar stock se actualiza en ambas sedes
- [ ] Verificar transacciones se crean en ambas sedes
- [ ] Rechazar transferencia (debe cancelarse)
- [ ] Intentar transferir más stock del disponible (debe fallar)
- [ ] Simular desconexión durante transferencia

**Entregable:** Transferencias entre sedes funcionales, operación atómica garantizada

---

## Fase 9: Reportes Consolidados (4-5 días)

### Backend

- [ ] Implementar InventoryModule
  - [ ] GET /inventory/consolidated (inventario total)
  - [ ] GET /inventory/by-sede (inventario por sede)
  - [ ] GET /inventory/low-stock (productos con stock bajo)
- [ ] Implementar caché con Redis
  - [ ] Cachear inventario consolidado
  - [ ] Invalidar caché al sincronizar
- [ ] Crear queries SQL optimizadas con agregaciones

### Web Admin (o Desktop App para Tenant Admin)

- [ ] Crear dashboard de Tenant Admin
  - [ ] Inventario total por producto
  - [ ] Inventario por sede
  - [ ] Productos con stock bajo
  - [ ] Indicador de última sincronización por sede
  - [ ] Advertencias de datos desactualizados
- [ ] Implementar gráficos (Chart.js o Recharts)
- [ ] Crear filtros y búsqueda

### Testing

- [ ] Verificar totales consolidados son correctos
- [ ] Verificar advertencias cuando sede está desincronizada
- [ ] Verificar caché de Redis funciona
- [ ] Probar con 3 sedes y 100+ productos

**Entregable:** Reportes consolidados funcionales, visibilidad multi-sede

---

## Fase 10: LAN Sync Multi-Caja (Opcional - 5-6 días)

### Desktop App

- [ ] Implementar LAN Sync Server (Caja Master)
  - [ ] Servidor WebSocket local (puerto 3001)
  - [ ] Broadcast de transacciones a cajas slave
  - [ ] Broadcast de cambios de inventario
- [ ] Implementar LAN Sync Client (Caja Slave)
  - [ ] Conectar a caja master via WebSocket
  - [ ] Escuchar eventos de transacciones
  - [ ] Actualizar SQLite local
- [ ] Crear UI de configuración
  - [ ] Seleccionar modo: Master o Slave
  - [ ] Configurar IP de caja master (para slaves)
  - [ ] Ver cajas conectadas (para master)

### Testing

- [ ] Configurar 3 cajas en misma red LAN
- [ ] Registrar venta en Caja 1 (master)
- [ ] Verificar Caja 2 y 3 (slaves) se actualizan
- [ ] Desconectar Caja 2 y verificar se reconecta
- [ ] Simular caída de Caja Master (failover)

**Entregable:** Múltiples cajas sincronizadas en tiempo real via LAN

---

## Fase 11: Módulo de IA (Normalizer) (5-6 días)

### Backend

- [ ] Implementar AIModule
  - [ ] POST /ai/normalize (normalizar productos)
  - [ ] Integración con OpenAI API
  - [ ] Rate limiting
  - [ ] Caché de resultados
- [ ] Crear lógica de detección de duplicados
- [ ] Implementar sugerencias de categorización

### Web Admin

- [ ] Crear UI para importar productos (CSV/Excel)
- [ ] Crear UI para revisar sugerencias de IA
  - [ ] Lista de productos similares
  - [ ] Sugerencias de nombres normalizados
  - [ ] Aprobar/rechazar en lote
- [ ] Implementar preview antes de aplicar cambios

### Testing

- [ ] Importar 50 productos con nombres inconsistentes
- [ ] Verificar IA detecta duplicados
- [ ] Aprobar sugerencias y verificar productos se unifican
- [ ] Verificar rate limiting funciona

**Entregable:** IA normaliza catálogos, reduce duplicados, mejora consistencia

---

## Fase 12: Auditoría y Logs (3-4 días)

### Backend

- [ ] Implementar AuditModule
  - [ ] Interceptor global para capturar acciones
  - [ ] Guardar en audit_logs
  - [ ] GET /audit/logs (consultar logs)
- [ ] Implementar filtros por usuario, acción, entidad

### Web Admin

- [ ] Crear UI de auditoría (solo admins)
  - [ ] Lista de logs
  - [ ] Filtros por fecha, usuario, acción
  - [ ] Detalles de cada acción (before/after)

### Testing

- [ ] Crear producto y verificar log se genera
- [ ] Editar producto y verificar before/after
- [ ] Filtrar logs por usuario
- [ ] Verificar logs de transferencias

**Entregable:** Sistema de auditoría completo, trazabilidad total

---

## Fase 13: Generación de Instaladores (4-5 días)

### Desktop App

- [ ] Configurar Tauri bundler
  - [ ] Windows (.exe con auto-updater)
  - [ ] macOS (.dmg firmado)
  - [ ] Linux (.AppImage, .deb)
- [ ] Configurar auto-update
  - [ ] Endpoint de updates en backend
  - [ ] Verificación de firmas
  - [ ] Descarga en background
  - [ ] Notificación al usuario
- [ ] Crear iconos para cada plataforma
- [ ] Configurar permisos y capabilities
- [ ] Optimizar bundle size

### Infraestructura

- [ ] Configurar CDN para instaladores (Cloudflare R2)
- [ ] Crear endpoint de distribución
- [ ] Implementar versionado semántico
- [ ] Crear release notes automáticas

### Testing

- [ ] Generar instaladores para Windows, macOS, Linux
- [ ] Instalar en cada plataforma
- [ ] Verificar auto-update funciona
- [ ] Verificar firma digital (macOS, Windows)

**Entregable:** Instaladores funcionales para todas las plataformas

---

## Fase 14: Testing y QA (5-7 días)

### Testing Funcional

- [ ] Crear suite de tests E2E (Playwright)
  - [ ] Flujo completo de venta offline
  - [ ] Sincronización después de offline
  - [ ] Transferencia entre sedes
  - [ ] Conflictos de sincronización
  - [ ] Activación de app
- [ ] Tests de integración backend (Jest)
  - [ ] Endpoints de sincronización
  - [ ] Transferencias atómicas
  - [ ] Multi-tenancy isolation
- [ ] Tests unitarios desktop app (Vitest)
  - [ ] Hooks de SQLite
  - [ ] Lógica de negocio
  - [ ] Validaciones

### Testing de Escenarios Adversos

- [ ] Pérdida de conexión durante venta
- [ ] Pérdida de conexión durante sincronización
- [ ] Pérdida de conexión durante transferencia
- [ ] Edición concurrente del mismo producto
- [ ] Cierre inesperado de la app
- [ ] Disco lleno
- [ ] Backend caído durante operación
- [ ] Corrupción de base de datos SQLite

### Testing de Rendimiento

- [ ] Venta de 100 productos simultáneos
- [ ] Sincronización de 1000 transacciones
- [ ] 10 usuarios concurrentes en misma sede
- [ ] 3 sedes sincronizando simultáneamente
- [ ] Base de datos con 10,000+ productos

**Entregable:** Suite de tests completa, bugs críticos resueltos

---

## Fase 15: Deployment y DevOps (3-4 días)

### Backend

- [ ] Configurar Railway (o alternativa)
- [ ] Configurar PostgreSQL managed
- [ ] Configurar Redis managed
- [ ] Variables de entorno en producción
- [ ] Configurar CI/CD (GitHub Actions)
- [ ] Setup de migraciones automáticas
- [ ] Configurar logs y monitoring (Sentry, LogRocket)

### Web Admin

- [ ] Configurar Vercel (o alternativa)
- [ ] Configurar variables de entorno
- [ ] Configurar CI/CD
- [ ] Configurar dominio personalizado

### Distribución de Instaladores

- [ ] Configurar Cloudflare R2 para CDN
- [ ] Subir instaladores
- [ ] Configurar auto-update endpoint
- [ ] Crear página de descarga

### Testing en Producción

- [ ] Smoke tests en producción
- [ ] Verificar instaladores se descargan correctamente
- [ ] Verificar auto-update funciona
- [ ] Verificar sincronización funciona
- [ ] Verificar WebSockets funcionan

**Entregable:** Aplicación desplegada en producción, CI/CD configurado

---

## Fase 16: Documentación y Pulido (2-3 días)

### Documentación

- [ ] README completo con instrucciones
- [ ] Documentación de API (Swagger/OpenAPI)
- [ ] Guía de usuario (desktop app)
- [ ] Guía de administrador (web admin)
- [ ] Troubleshooting común
- [ ] Guía de instalación por plataforma

### Pulido de UI/UX

- [ ] Revisar consistencia de diseño
- [ ] Mejorar mensajes de error
- [ ] Agregar loading states
- [ ] Mejorar feedback visual
- [ ] Optimizar para diferentes resoluciones
- [ ] Agregar atajos de teclado

**Entregable:** Aplicación pulida, documentación completa

---

## Estimación Total

| Fase | Duración Estimada |
|------|-------------------|
| 0. Setup Inicial | 2-3 días |
| 1. Autenticación y Multi-Tenancy | 3-4 días |
| 2. Base de Datos Local (SQLite) | 4-5 días |
| 3. Productos e Inventario | 5-6 días |
| 4. Transacciones (POS) | 4-5 días |
| 5. Backend Sincronización | 5-6 días |
| 6. Motor de Sincronización | 5-6 días |
| 7. Gestión de Sedes | 3-4 días |
| 8. Transferencias | 7-8 días |
| 9. Reportes Consolidados | 4-5 días |
| 10. LAN Sync (Opcional) | 5-6 días |
| 11. IA Normalizer | 5-6 días |
| 12. Auditoría | 3-4 días |
| 13. Instaladores | 4-5 días |
| 14. Testing y QA | 5-7 días |
| 15. Deployment | 3-4 días |
| 16. Documentación | 2-3 días |
| **TOTAL (sin LAN Sync)** | **65-81 días (~3-4 meses)** |
| **TOTAL (con LAN Sync)** | **70-87 días (~3.5-4.5 meses)** |

---

## Notas Importantes

### Diferencias clave con v1

1. **Desktop apps** requieren más setup inicial pero ofrecen mejor persistencia
2. **SQLite** es más confiable que IndexedDB pero requiere aprender SQL nativo
3. **Códigos de activación** agregan complejidad pero mejoran seguridad
4. **Auto-update** es crítico para mantener apps actualizadas
5. **LAN sync** es opcional pero muy valioso para multi-caja

### Recomendaciones

- **Prioriza la app de escritorio** sobre la web admin
- **Usa Tauri** en lugar de Electron si es posible (menor tamaño)
- **Implementa auto-update** desde el inicio
- **Prueba en múltiples plataformas** regularmente
- **Mantén backups** de SQLite durante desarrollo

### Recursos Útiles

- [Tauri Documentation](https://tauri.app/)
- [SQLite Documentation](https://www.sqlite.org/docs.html)
- [Prisma Documentation](https://www.prisma.io/docs)
- [NestJS Documentation](https://docs.nestjs.com/)
