# Documento de Definición de Requerimientos
# Proyecto: Stocky
# SaaS Multi-Tenant con Arquitectura Híbrida Cloud-Edge

### 1. Objetivo del Proyecto
Desarrollar una plataforma SaaS de gestión de inventarios con arquitectura híbrida cloud-edge, diseñada para operar de forma confiable en entornos con conectividad inestable o inexistente. El sistema combina un hub centralizado en la nube (fuente de verdad global) con aplicaciones locales instalables en cada punto de venta (autonomía operativa) mediante sincronización bidireccional robusta.

El proyecto busca demostrar dominio en:

    • Diseño de aplicaciones híbridas cloud-edge
    • Arquitecturas distribuidas con sincronización robusta
    • Gestión de consistencia eventual con resolución de conflictos
    • Arquitecturas SaaS multi-tenant seguras
    • Desarrollo de aplicaciones de escritorio modernas (Electron/Tauri)
    • Sistemas POS resilientes para entornos adversos

Nota: Las decisiones técnicas específicas (algoritmos de sincronización, estructura de base de datos, protocolos de transferencia, etc.) se documentarán en un Documento de Arquitectura independiente.

### 2. Modelo de Arquitectura Híbrida

#### 2.1 Principio Fundamental
El sistema implementa una arquitectura híbrida cloud-edge donde:

    • La nube es la fuente de verdad global para toda la organización
    • Cada sede física opera con aplicación local instalada (Electron/Tauri) con base de datos SQLite
    • Sincronización bidireccional robusta con detección y resolución de conflictos
    • Autonomía operativa garantizada: las sedes pueden operar indefinidamente sin internet
    • Coordinación entre cajas en LAN para sedes con múltiples puntos de venta

#### 2.2 Componentes de la Arquitectura
Hub Online (Nube):

    • PostgreSQL: Base de datos maestra con todo el estado del tenant
    • Redis: Caché, pub/sub para notificaciones en tiempo real
    • API NestJS: Gestión de tenants, usuarios, sincronización, transferencias
    • Interfaz web administrativa: Configuración inicial, reportes consolidados

Aplicación Local (Punto de Venta):

    • App de escritorio: Electron o Tauri (instalable en Windows/macOS/Linux)
    • SQLite local: Base de datos completa con productos, inventario, transacciones
    • UI web embebida: React servido localmente por la app
    • Motor de sincronización: Background service para push/pull con la nube
    • Servidor LAN opcional: Una caja puede actuar como hub local para sincronizar otras cajas de la misma tienda

#### 2.3 La Nube como Fuente de Verdad
Decisión crítica: La nube SÍ es la fuente de verdad global. Esto significa:

    • Conflictos se resuelven con prioridad a la nube cuando no hay estrategia obvia (Last-Write-Wins con timestamp del servidor)
    • Inventario consolidado en la nube es autoritativo para reportes y análisis
    • Transferencias entre tiendas requieren validación en la nube para garantizar atomicidad
    • Configuraciones estructurales (usuarios, roles, productos maestros) se crean en la nube y se descargan a las sedes

Autonomía se mantiene:

    • Sedes operan indefinidamente sin internet para operaciones locales (ventas, consultas, ajustes)
    • La nube es fuente de verdad, pero NO gatekeep de operaciones críticas locales
    • Sincronización es eventual, no bloqueante

#### 2.4 Separación Clara de Responsabilidades
Operaciones Locales (SQLite en Aplicación Local):

    • Ventas y transacciones de salida
    • Entradas de inventario (recepciones, ajustes locales)
    • Consultas de stock disponible
    • Búsqueda y visualización de productos
    • Funcionan 100% offline, sin ninguna dependencia del backend
    • Cambios se sincronizan en background cuando hay internet

Operaciones Centralizadas (Backend en la Nube):

    • Configuración de tenants, sedes, usuarios
    • Creación y gestión de catálogo maestro de productos
    • Solicitudes de transferencia entre tiendas
    • Reportes consolidados multi-sede
    • Módulo de IA para normalización de catálogo
    • Requieren internet, pero no bloquean operaciones locales

Operaciones Coordinadas (Requieren ambos):

    • Aprobación de transferencias (backend + SQLite de sede origen)
    • Sincronización bidireccional de inventario
    • Propagación de cambios de configuración

#### 2.5 Implicaciones de Diseño
Ventajas de este modelo:

    • Confiabilidad: SQLite + Electron garantiza persistencia, IndexedDB no
    • Múltiples cajas sincronizadas en LAN: Inventario compartido en tiempo real localmente
    • Sin límites de almacenamiento: SQLite puede manejar millones de registros
    • Base de datos SQL completa: Queries complejas, joins, transacciones ACID localmente
    • Instalación one-time: Después de instalar, funciona para siempre offline
    • Backup automático: App puede hacer backups locales periódicos del SQLite

Trade-offs aceptados:

    • Requiere instalación: No es 100% web, necesita instalar aplicación
    • Complejidad de distribución: Hay que distribuir instaladores (Windows .exe, macOS .dmg, Linux .deb)
    • Actualizaciones de app: Requiere sistema de auto-actualización
    • Mayor complejidad técnica: Electron/Tauri + sincronización custom vs PWA simple

### 3. Alcance Funcional General
El sistema cubrirá las operaciones esenciales de inventario necesarias para que cada sede pueda continuar operando aún sin conexión a internet. La aplicación local prioriza:

    • Autonomía operativa total mediante base de datos SQLite persistente
    • Sincronización robusta en background sin bloquear la UI
    • Coordinación entre múltiples cajas en la misma tienda via LAN
    • Experiencia de usuario fluida entre modos online/offline

Restricciones aceptadas:

    • Configuración inicial y ciertas tareas administrativas requieren internet
    • Transferencias entre tiendas requieren conectividad de ambas partes
    • Módulo de IA es online-only

### 4. Módulos de la Aplicación

#### 4.1 Aplicación Web (Admin Cloud)
Plataforma: Web app en React servida desde la nube

Funcionalidades:

    • Registro de tenants y suscripción
    • Configuración de organización (logo, datos fiscales)
    • Creación y gestión de sedes
    • Creación de usuarios y asignación de roles
    • Creación y gestión del catálogo maestro de productos
    • Descarga de instaladores de la aplicación local
    • Reportes consolidados multi-sede
    • Dashboard ejecutivo con métricas de negocio
    • Módulo de IA para normalización masiva de catálogo

#### 4.2 Aplicación Local (POS Desktop App)
Plataforma: Electron o Tauri (instalable)

Funcionalidades Offline:

    • Registro de ventas y salidas de inventario
    • Entradas de inventario (recepciones, ajustes)
    • Consultas de stock en tiempo real (desde SQLite local)
    • Búsqueda de productos
    • Historial de transacciones
    • Reportes locales (ventas del día, productos más vendidos)
    • Configuración de la caja (impresora térmica, lector de códigos)

Funcionalidades Online:

    • Sincronización bidireccional con la nube
    • Recepción de transferencias aprobadas
    • Actualización de catálogo maestro desde la nube
    • Notificaciones push de eventos importantes

Funcionalidades LAN (Multi-caja):

    • Sincronización en tiempo real con otras cajas de la tienda
    • Propagación inmediata de cambios de inventario
    • Elección de caja Master/Slave
    • Failover automático si caja Master cae

#### 4.3 Core & Multi-Tenancy
    • Gestión de organizaciones (tenants) de forma completamente aislada
    • Cada tenant tiene múltiples sedes
    • Ningún usuario o proceso puede acceder a información de otro tenant
    • Base para control de usuarios, permisos, configuración general

#### 4.4 Gestión de Sedes y Transferencias
    • Registro y configuración de sedes físicas desde la web administrativa
    • Sistema de solicitudes de transferencia de inventario entre sedes
    • Flujo de aprobación/rechazo con validación de stock
    • Ejecución atómica de transferencias (descuenta origen, suma destino)
    • Notificaciones en tiempo real via WebSocket

Restricción crítica: Transferencias solo se ejecutan si ambas sedes están online. Esto garantiza atomicidad y evita estados inconsistentes.

#### 4.5 Inventario Inteligente (AI-Powered)
    • CRUD de productos desde web administrativa
    • Catálogo maestro sincronizado a todas las sedes
    • Importación masiva desde Excel/CSV
    • Sub-módulo AI Normalizer: sugiere nombres normalizados, detecta productos duplicados, categorización automática, unificación de descripciones similares

La IA actúa como asistente: Todas las sugerencias requieren aprobación humana.

Restricción: Módulo de IA es online-only y solo disponible desde la web administrativa.

#### 4.6 Motor de Sincronización
En la aplicación local:

    • Detección automática de conectividad (ping periódico al backend)
    • Push queue: Cola persistente en SQLite de cambios pendientes de sincronizar
    • Pull handler: Descarga cambios desde la nube
    • Conflict resolver: Resuelve conflictos con estrategias configurables
    • Retry logic: Reintenta sincronización con backoff exponencial
    • Indicadores visuales de estado de sincronización

Estrategias de resolución de conflictos:

    • Last-Write-Wins (LWW): Para campos editables como precio, descripción (usa timestamp del servidor)
    • Append-only: Para transacciones (no hay conflictos, se acumulan)
    • Cloud-wins: Para configuraciones estructurales (usuarios, roles, permisos)
    • Manual: Para casos ambiguos, se notifica al usuario para decisión

#### 4.7 Módulo de Transacciones (POS Core)
    • Registro rápido de ventas
    • Búsqueda de productos por SKU, código de barras, nombre
    • Cálculo automático de totales, descuentos, impuestos
    • Integración con impresora térmica (tickets)
    • Integración con lector de códigos de barras
    • Métodos de pago (efectivo, tarjeta, transferencia)
    • Funcionamiento 100% offline garantizado
    • Persistencia inmediata en SQLite (sin pérdida de datos)

#### 4.8 Auditoría y Logs
Registro inmutable de acciones relevantes:

    • Quién realizó el cambio (userId)
    • Qué entidad fue afectada (product, inventory, transaction)
    • Cuándo ocurrió (timestamp local + timestamp de sincronización)
    • En qué sede se originó
    • Si la operación se hizo online u offline

Almacenamiento:

    • Local: SQLite (audit_log table)
    • Nube: PostgreSQL (tras sincronización)

### 5. Usuarios, Roles y Permisos (RBAC)

#### 5.1 Super Admin (Plataforma)
    • Acceso a todos los tenants
    • Métricas de uso de la plataforma
    • Gestión de suscripciones
    • Configuración de features flags

#### 5.2 Tenant Admin (Dueño del Negocio)
    • Acceso total a los datos de su organización
    • Gestión de usuarios, roles, sedes
    • Creación de productos en catálogo maestro
    • Aprobación de transferencias entre sedes
    • Reportes consolidados multi-sede
    • Acceso a módulo de IA
    • Descarga de instaladores de la app local

#### 5.3 Store Manager (Gerente de Sede)
    • Gestión de inventario en su sede
    • Aprobación/rechazo de transferencias que afecten su sede
    • Reportes operativos de su sede
    • Configuración de la aplicación local
    • Gestión de cajas (configurar Master/Slave)

#### 5.4 Staff (Operario / Vendedor)
    • Registro de ventas desde la app local
    • Consulta de stock disponible
    • Búsqueda de productos
    • No puede: eliminar productos, ver costos, aprobar transferencias

### 6. Historias de Usuario y Casos de Uso Críticos

#### Epic: Instalación y Configuración Inicial
HU-01: Como Tenant Admin, quiero registrarme en la plataforma web, crear mi organización y configurar mis sedes para comenzar a usar el sistema. <br>
HU-02: Como Tenant Admin, quiero descargar el instalador de la aplicación local para cada una de mis sedes y activarlas con un código único. <br>
HU-03: Como Store Manager, quiero activar la aplicación local en mi punto de venta ingresando el código de activación y descargar la configuración inicial (productos, usuarios) desde la nube.

#### Epic: Operatividad Offline
HU-04: Como Vendedor, quiero registrar ventas sin conexión a internet desde la aplicación local sin ninguna limitación de funcionalidad. <br>
HU-05: Como Sistema (app local), debo persistir todas las transacciones en SQLite inmediatamente y sincronizarlas en background cuando haya internet, sin perder ningún dato. <br>
HU-06: Como Vendedor, quiero ver claramente en la interfaz si estoy online u offline y cuántos cambios están pendientes de sincronizar.

#### Epic: Multi-Caja (LAN Sync)
HU-07: Como Store Manager, quiero configurar múltiples cajas en mi tienda para que se sincronicen entre ellas via red local y compartan el inventario en tiempo real. <br>
HU-08: Como Vendedor en Caja 2, cuando un producto se vende en Caja 1, quiero ver el stock actualizado en menos de 1 segundo para evitar vender inventario inexistente. <br>
HU-09: Como Sistema, si la caja Master se cae, debo promover automáticamente otra caja a Master para que la tienda siga operando sin interrupciones.

#### Epic: Transferencias entre Sedes
HU-10: Como Store Manager, quiero solicitar productos de otra sede online para abastecer mi tienda (requiere internet). <br>
HU-11: Como Store Manager, quiero aprobar o rechazar solicitudes de transferencia desde mi sede, validando que cuento con el stock disponible antes de comprometer el envío. <br>
HU-12: Como Sistema, debo garantizar que las transferencias entre sedes sean atómicas: si alguna sede pierde conexión durante el proceso, debo revertir la operación completa.

#### Epic: Sincronización Robusta
HU-13: Como Sistema (app local), debo detectar conflictos cuando la misma entidad se modifica offline en múltiples sedes y resolverlos según la estrategia configurada (LWW, Cloud-wins, Manual). <br>
HU-14: Como Sistema, si la sincronización falla por problemas de red, debo reintentar automáticamente con backoff exponencial hasta que se complete. <br>
HU-15: Como Vendedor, cuando la sincronización se completa exitosamente, debo ver una confirmación visual clara de que mis cambios ya están en la nube.

#### Epic: Visibilidad Consolidada
HU-16: Como Tenant Admin, quiero ver reportes consolidados del inventario de todas mis sedes desde la web administrativa para tomar decisiones estratégicas. <br>
HU-17: Como Tenant Admin, cuando visualizo reportes consolidados, debo ver claramente qué sedes están sincronizadas y cuál fue su última actualización para entender si los datos están completos.

#### Epic: Automatización con IA
HU-18: Como Tenant Admin, quiero importar un catálogo masivo desde Excel y recibir sugerencias de normalización automática desde el módulo de IA para aprobarlas en lote. <br>
HU-19: Como Tenant Admin, quiero que el sistema detecte productos duplicados en mi catálogo y me sugiera unificarlos automáticamente.

### 7. Consideraciones Funcionales

#### 7.1 Comportamiento Offline (Aplicación Local)
El sistema PERMITE en modo offline:

    • Registro de transacciones (ventas, entradas, ajustes)
    • Consulta de inventario local
    • Búsqueda de productos
    • Reportes locales (ventas del día, productos más vendidos)
    • Configuración de impresora y lector de códigos
    • Visualización del historial de transacciones local

El sistema NO PERMITE en modo offline:

    • Configuración de usuarios y roles
    • Solicitudes de transferencia entre tiendas
    • Aprobación/rechazo de transferencias (requiere validación en nube)
    • Reportes consolidados multi-sede
    • Módulo de IA (normalización de catálogo)
    • Descarga de actualizaciones de catálogo maestro
    • Creación de nuevas sedes

#### 7.2 Persistencia Local
Garantías:

    • SQLite como base de datos local - Persistencia garantizada, no hay riesgo de borrado como IndexedDB
    • Todas las transacciones se escriben inmediatamente - Modo WAL (Write-Ahead Logging) para durabilidad
    • Backups automáticos locales - La app puede hacer backups periódicos del archivo SQLite
    • Sin límites de almacenamiento prácticos - SQLite puede manejar cientos de miles de productos y transacciones

Alcance de almacenamiento local:

    • Base de datos completa de inventario de la sede
    • Catálogo maestro de productos (sincronizado desde la nube)
    • Cola de operaciones pendientes de sincronización
    • Configuraciones de la sede y usuarios locales
    • Historial completo de transacciones

Monitoreo:

    • La app monitorea el tamaño del archivo SQLite
    • Si supera un umbral (ej. 1GB), sugiere archivar transacciones antiguas
    • La nube puede solicitar que la app archive transacciones > 1 año en un backup

#### 7.3 Indicadores Visuales
La interfaz de la aplicación local debe comunicar claramente:

    • Estado de conexión: Online (verde), Offline (gris), Sincronizando (amarillo)
    • Cantidad de cambios pendientes: "15 transacciones pendientes de sincronizar"
    • Progreso de sincronización: Barra de progreso con porcentaje
    • Última sincronización exitosa: "Última sincronización: hace 5 minutos"
    • Conflictos detectados: Notificación si hay conflictos que requieren atención
    • Estado de otras cajas (LAN): "Caja 2: Online | Caja 3: Offline"

En la web administrativa (reportes consolidados):

    • Timestamp de última sincronización por sede
    • Advertencias sobre sedes desactualizadas (> 24 horas sin sincronizar)
    • Indicador visual de sedes online vs offline

### 8. Consideraciones No Funcionales

#### 8.1 Rendimiento
    • Las operaciones locales (ventas, consultas) deben tener latencia < 50ms (SQLite es extremadamente rápido)
    • La sincronización debe ejecutarse en background sin bloquear la UI
    • La app debe usar menos de 200MB de RAM en idle
    • Queries a SQLite deben estar optimizadas con índices apropiados
    • La sincronización debe usar compresión (gzip) para reducir transferencia de datos

#### 8.2 Seguridad
Aislamiento de datos:

    • PostgreSQL: Row-Level Security, tenantId en todas las tablas
    • SQLite local: Solo datos del tenant y sede correspondiente
    • Validación de permisos en backend independientemente del estado del cliente

Protección de datos locales:

    • SQLite puede encriptarse con SQLCipher (opcional)
    • Sesión JWT almacenada de forma segura
    • Auto-logout después de 8 horas de inactividad

Comunicación:

    • HTTPS/TLS para todas las conexiones al backend
    • WebSocket sobre WSS (seguro)
    • Validación de certificados SSL

#### 8.3 Distribución de la Aplicación
Instaladores:

    • Windows: .exe con auto-actualización (Squirrel.Windows o electron-builder)
    • macOS: .dmg con firma de desarrollador
    • Linux: .deb, .AppImage

Auto-actualización:

    • La app verifica actualizaciones al iniciar (si hay internet)
    • Descarga updates en background
    • Notifica al usuario y solicita reinicio
    • Rollback automático si la actualización falla

Activación:

    • Código de activación de un solo uso por sede
    • Validación contra backend (requiere internet la primera vez)
    • Después de activar, funciona offline indefinidamente

#### 8.4 Escalabilidad
Por sede:

    • SQLite puede manejar hasta ~1M de productos sin problemas
    • Transacciones: Archivado automático después de 1 año
    • Productos: No hay límite práctico

Por tenant:

    • Backend puede manejar miles de sedes concurrentes
    • Redis para caché de inventario consolidado (reduce carga en PostgreSQL)
    • Queries a PostgreSQL optimizadas con índices y partitioning por tenant

### 9. Observabilidad y Administración
Métricas desde la web administrativa:

    • Estado de sincronización por sede (online/offline, última sync)
    • Número de operaciones pendientes de sincronizar por sede
    • Volumen de transacciones procesadas (diario, semanal, mensual)
    • Errores de sincronización y conflictos detectados
    • Estado de transferencias entre sedes
    • Uso de almacenamiento local por sede

Herramientas de soporte:

    • Super Admin puede acceder a logs de cualquier sede
    • Capacidad de forzar re-sincronización completa remotamente
    • Dashboard de salud del sistema (latencias, errores, uptime)

### 10. Estrategia de Pruebas (Alto Nivel)
Pruebas críticas:

    • Persistencia: Cerrar app abruptamente (kill process) con transacciones pendientes, verificar que no se pierden al reabrir
    • Sincronización: Editar mismo producto offline en 2 sedes distintas, reconectar ambas, verificar resolución de conflicto
    • Multi-caja: Vender producto en Caja 1, verificar que Caja 2 ve stock actualizado en < 1s via LAN
    • Transferencias atómicas: Iniciar transferencia, desconectar sede destino, verificar rollback
    • Offline prolongado: Operar 7 días sin internet, reconectar, verificar sincronización completa
    • Corrupción de SQLite: Simular corrupción de base de datos, verificar que la app detecta y ofrece restaurar backup
    • Actualizaciones: Probar auto-actualización de versiones (upgrade, rollback)
    • Aislamiento multi-tenant: Intentar acceder a datos de otro tenant manipulando requests, verificar rechazo

### 11. Fuera de Alcance
    • Sincronización peer-to-peer entre sedes sin pasar por la nube
    • Modo kiosko (pantalla completa sin acceso a sistema operativo)
    • Integración con sistemas contables externos
    • Gestión de compras a proveedores
    • CRM o fidelización de clientes
    • E-commerce integrado
    • Reportes financieros avanzados (flujo de caja, balance)

Este documento define qué hace el sistema y por qué. Las decisiones de implementación detalladas se documentarán en el Documento de Arquitectura.
