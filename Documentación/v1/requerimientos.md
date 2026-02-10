# Documento de Definición de Requerimientos
# Proyecto: Stocky
# SaaS Multi-Tenant con Arquitectura Distribuida Offline-First

### 1. Objetivo del Proyecto
Desarrollar una plataforma SaaS de gestión de inventarios offline-first, diseñada para operar de forma confiable en entornos con conectividad inestable o inexistente. El sistema permitirá a múltiples organizaciones (tenants) gestionar su inventario de manera completamente aislada, con una arquitectura distribuida donde cada sede mantiene autonomía operativa mediante su propia base de datos local.

El proyecto busca demostrar dominio en:

    • Diseño de aplicaciones resilientes (offline-first)
    • Arquitecturas distribuidas con autonomía de datos por sede
    • Gestión de consistencia eventual en sistemas multi-sede
    • Arquitecturas SaaS multi-tenant seguras
    • Experiencia de usuario robusta bajo condiciones adversas
    • Uso práctico de Inteligencia Artificial como asistente de negocio
Nota: Las decisiones técnicas específicas (algoritmos de sincronización, versionado, protocolos de transferencia, etc.) se documentarán en un Documento de Arquitectura independiente.

### 2. Modelo de Arquitectura Distribuida

#### 2.1 Principio Fundamental
El sistema implementa una arquitectura distribuida basada en autonomía de sede, donde:

    • Cada sede física (tienda, sucursal, punto de venta) mantiene su propia base de datos local con su inventario completo
    • El backend en la nube actúa como hub centralizado para operaciones inter-sede, no como fuente única de verdad para inventario local
    • Cada sede opera de forma completamente autónoma para todas sus operaciones locales, sin depender de la nube
    • La sincronización es selectiva: solo se sincronizan datos necesarios para visibilidad consolidada y operaciones entre sedes

#### 2.2 Ejemplo Ilustrativo
Tenant: Empresa X (cadena de retail)
Sedes: Tienda A, Tienda B, Tienda C
Arquitectura de datos:

    • Tienda A tiene su base de datos local con inventario completo de sus productos
    • Tienda B tiene su base de datos local con inventario completo de sus productos
    • Tienda C tiene su base de datos local con inventario completo de sus productos
    • El backend en la nube almacena vistas consolidadas y gestiona operaciones inter-sede

Flujo operativo:

    1. Operación local: Un cliente compra un producto en Tienda A → la venta se registra inmediatamente en la base de datos local de Tienda A, incluso sin internet.
    2. Sincronización: Cuando Tienda A recupera conexión, sincroniza sus cambios con el backend en la nube para visibilidad consolidada.
    3. Operación inter-sede: Desde el backend, el administrador solicita transferir productos de Tienda B a Tienda A. Esta operación requiere que ambas tiendas estén online para confirmar disponibilidad y ejecutar la transferencia de forma coordinada.
#### 2.3 Separación Clara de Responsabilidades
Operaciones Locales (Base de Datos Local de la Sede)

    • Ventas y transacciones de salida
    • Entradas de inventario (recepciones, ajustes)
    • Consultas de stock disponible
    • Gestión local de productos
    • Funcionan 100% offline, sin ninguna dependencia del backend
Operaciones Inter-Sede (Backend en la Nube)

    • Solicitudes de transferencia de inventario entre sedes
    • Aprobación/rechazo de solicitudes de transferencia
    • Reportes consolidados multi-sede
    • Visibilidad de inventario en tiempo real de todas las sedes
    • Requieren conectividad y que todas las sedes involucradas estén online

#### 2.4 Implicaciones de Diseño
Ventajas de este modelo:

    • Eliminación de conflictos de inventario: Cada sede gestiona su propio stock de forma aislada. No hay dos bases de datos compitiendo por la misma unidad de inventario.
    • Autonomía operativa total: Una tienda puede operar indefinidamente sin internet sin perder funcionalidad crítica.
    • Escalabilidad natural: Agregar nuevas sedes no aumenta la complejidad de sincronización de inventario local.
    • Modelo mental claro: Cada sede es dueña de su inventario físico y de sus datos.
Trade-offs aceptados:

    • Transferencias requieren conectividad: No se pueden solicitar productos de otra sede mientras se está offline. Esto es una decisión pragmática para evitar complejidad innecesaria.
    • Reportes consolidados pueden estar desactualizados: Si una sede está offline, los reportes multi-sede mostrarán advertencias sobre la última sincronización.
    • No hay inventario 'virtual' compartido: El inventario es físico y pertenece a una sede específica. Las transferencias son operaciones explícitas.

### 3. Alcance Funcional General
El sistema cubrirá las operaciones esenciales de inventario necesarias para que cada sede pueda continuar operando aun sin conexión a internet, priorizando:

    • Transacciones de stock locales sobre tareas administrativas
    • Autonomía operativa de cada sede sobre sincronización en tiempo real
    • Simplicidad y consistencia sobre disponibilidad total de todas las funcionalidades offline

Se considera explícitamente que no todas las funcionalidades estarán disponibles en modo offline, privilegiando la integridad de los datos y la simplicidad operativa.
### 4. Módulos de la Aplicación
#### 4.1 Core & Multi-Tenancy
    • Gestión de organizaciones (tenants) de forma completamente aislada
    • Cada tenant cuenta con múltiples sedes, cada una con su propia base de datos local
    • Ningún usuario o proceso puede acceder a información de otro tenant
    • Base para control de usuarios, permisos, configuración general y gestión de sedes
#### 4.2 Gestión de Sedes y Transferencias
    • Registro y configuración de sedes físicas (tiendas, sucursales, almacenes)
    • Sistema de solicitudes de transferencia de inventario entre sedes
    • Flujo de aprobación/rechazo de transferencias
    • Validación de disponibilidad en sede origen antes de aprobar transferencia
    • Ejecución atómica de transferencias (descuenta de origen, suma a destino)
Restricción crítica: Solo se pueden realizar solicitudes de transferencia a sedes que estén online. Esto garantiza que la sede origen pueda confirmar disponibilidad real antes de comprometer el inventario.
#### 4.3 Inventario Inteligente (AI-Powered)
    • CRUD de productos e inventario a nivel de sede
    • Soporte para catálogos con datos no estandarizados
    • Sub-módulo AI Normalizer que sugiere nombres normalizados, categorías y unificación de descripciones similares
La IA actúa como asistente: todas las sugerencias requieren aprobación humana antes de aplicarse.
Restricción: El módulo de IA es online-only. Las sugerencias de normalización requieren conexión al backend y no estarán disponibles sin conectividad.
#### 4.4 Motor de Sincronización (Sync Engine)
    • Detección automática del estado de la red
    • Envío de cambios locales al backend cuando se recupera conexión
    • Recepción de actualizaciones desde el backend (configuraciones, datos de catálogo compartido)
    • Gestión de cola de operaciones pendientes offline
    • Manejo de conflictos para campos editables concurrentemente (productos, configuraciones)
Alcance de sincronización:

        ◦ Transacciones de inventario (ventas, entradas, ajustes) → se sincronizan para visibilidad consolidada
        ◦ Cambios en productos y catálogo → se sincronizan bidireccionalmente
        ◦ Configuraciones y datos maestros → se reciben del backend
#### 4.5 Módulo de Transacciones (POS Lite)
    • Registro rápido de entradas y salidas de inventario
    • Optimizado para uso intensivo en modo offline
    • Prioridad máxima en estabilidad y simplicidad
    • Este módulo debe permitir que la operación del negocio de cada sede nunca se detenga, incluso sin conexión durante largos períodos.
#### 4.6 Auditoría y Logs
Registro inmutable de acciones relevantes:

    • Quién realizó el cambio
    • Qué entidad fue afectada
    • Cuándo ocurrió la acción
    • En qué sede se originó la operación
    • Incluye operaciones creadas offline y sincronizadas posteriormente
Este módulo es crítico para trazabilidad, resolución de conflictos, control administrativo y auditoría de transferencias entre sedes.
### 5. Usuarios, Roles y Permisos (RBAC)
#### 5.1 Super Admin (Plataforma)
    • Acceso global al sistema
    • Monitoreo de salud general y métricas por tenant
    • Gestión de suscripciones y configuración de la plataforma
#### 5.2 Tenant Admin (Dueño del Negocio)
    • Acceso total a los datos de su organización (todas las sedes)
    • Gestión de usuarios, roles, sedes y configuración del tenant
    • Creación y aprobación de solicitudes de transferencia entre sedes
    • Visualización de reportes consolidados multi-sede
#### 5.3 Store Manager (Gerente de Sede)
    • Gestión de inventario en su sede asignada
    • Ajustes manuales de stock
    • Aprobación/rechazo de solicitudes de transferencia que afecten su sede
    • Acceso a reportes operativos de su sede
#### 5.4 Staff (Operario / Vendedor)
    • Registro de movimientos de inventario en su sede (ventas, entradas)
    • Consulta de stock disponible en su sede
    • Acceso restringido: no puede eliminar productos ni ver costos internos
### 6. Historias de Usuario y Casos de Uso Críticos
#### Epic: Operatividad Offline por Sede
HU-01: Como Vendedor, quiero registrar salidas de inventario sin conexión a internet para no detener la operación del negocio en mi sede. <br>
HU-02: Como Sistema, debo sincronizar automáticamente los cambios pendientes de cada sede al recuperar conexión, sin interrumpir la experiencia del usuario.<br>
#### Epic: Transferencias entre Sedes
HU-03: Como Gerente de Sede, quiero solicitar productos de otra sede online para abastecer mi tienda cuando necesite inventario adicional.<br>
HU-04: Como Gerente de Sede, quiero aprobar o rechazar solicitudes de transferencia desde mi sede, validando que cuento con el stock disponible antes de comprometer el envío.<br>
HU-05: Como Sistema, debo garantizar que las transferencias entre sedes sean atómicas y que no se generen inconsistencias en el inventario de ninguna sede involucrada.
#### Epic: Visibilidad Consolidada
HU-06: Como Tenant Admin, quiero ver reportes consolidados del inventario de todas mis sedes para tomar decisiones estratégicas sobre distribución de productos.<br>
HU-07: Como Usuario, cuando visualizo reportes consolidados, debo ver claramente qué sedes están sincronizadas y cuál fue la última actualización de cada una, para entender si los datos están completos o parciales.<br>
#### Epic: Integridad y Consistencia de Datos
HU-08 (Conflictos): Como Sistema, debo manejar conflictos cuando múltiples usuarios modifican la misma información de producto en distintas sedes o estados de conectividad, aplicando una política de resolución por defecto o solicitando intervención manual cuando sea necesario. <br>

Política de Conflictos (Regla de Negocio):

    • Campos de productos (precio, nombre, descripción): política Last-Write-Wins basada en timestamp del servidor.
    • Transacciones de inventario: modelo acumulativo append-only para evitar sobreescrituras. Cada sede acumula sus propias transacciones sin conflicto.
    • Logs y auditoría: siempre append-only, sin sobrescritura.
#### Epic: Automatización con IA
HU-09: Como Admin, quiero importar un catálogo masivo (ej. Excel) y recibir sugerencias de normalización automática para aprobarlas en lote y mantener consistencia en el catálogo de productos entre sedes. <br>
### 7. Consideraciones Funcionales
#### 7.1 Comportamiento Offline
El sistema debe permitir en modo offline (a nivel de sede):

    • Registro de transacciones (ventas, entradas, ajustes)
    • Consulta de inventario de la sede
    • Creación y edición básica de productos en catálogo local
El sistema NO permitirá en modo offline:

    • Gestión de usuarios y roles
    • Solicitudes de transferencia entre sedes
    • Aprobación/rechazo de transferencias
    • Visualización de reportes consolidados multi-sede
    • Cambios estructurales del tenant (creación de nuevas sedes)
    • Ejecución del módulo de Inteligencia Artificial (AI Normalizer es online-only)
#### 7.2 Persistencia Local
    • Ninguna operación realizada offline puede perderse al cerrar el navegador o la aplicación.
    • Las operaciones pendientes permanecerán almacenadas localmente hasta su sincronización exitosa.
    • El sistema debe monitorear el uso de almacenamiento local del navegador.
    • Si se supera un umbral seguro de almacenamiento (ej. 50MB), se notificará al usuario y se bloqueará temporalmente la creación de nuevas operaciones con contenido pesado hasta completar la sincronización.
Alcance de almacenamiento local:

        ◦ Base de datos completa de inventario de la sede
        ◦ Cola de operaciones pendientes de sincronización
        ◦ Configuraciones y catálogo maestro de productos

#### 7.3 Indicadores Visuales
La interfaz debe comunicar claramente:

    • Estado de conexión de la sede
    • Cantidad de cambios pendientes de sincronización
    • Progreso de sincronización en segundo plano
    • Confirmación visual de datos sincronizados exitosamente
    • En reportes consolidados: última sincronización de cada sede y advertencias sobre datos potencialmente desactualizados
### 8. Consideraciones No Funcionales
#### 8.1 Rendimiento
    • La sincronización debe ejecutarse en segundo plano
    • La interfaz no debe bloquearse durante procesos de envío o recepción de datos
    • Las operaciones locales (ventas, consultas) deben tener latencia < 100ms independientemente del estado de conexión
#### 8.2 Seguridad
    • Aislamiento estricto entre tenants
    • Aislamiento de datos entre sedes (cada sede solo accede a su inventario local)
    • Validación de permisos en backend independientemente del estado del cliente
    • Protección contra accesos no autorizados incluso mediante manipulación de requests
    • Transferencias entre sedes deben validar autenticidad y permisos de ambas partes involucradas
#### 8.3 Seguridad Offline
    • Manejo controlado de sesiones cuando el usuario permanece offline por largos períodos
    • Protección razonable de la información almacenada localmente en la base de datos de la sede
### 9. Observabilidad y Administración
Métricas generales del sistema:

    • Estado de sincronización por tenant y por sede
    • Número de sedes online/offline por tenant
    • Volumen de operaciones offline pendientes por sede
    • Número de conflictos detectados en sincronización
    • Estado de transferencias entre sedes (pendientes, aprobadas, rechazadas)
    • Herramientas para diagnóstico y soporte desde el rol Super Admin
### 10. Estrategia de Pruebas (Alto Nivel)
Las pruebas se enfocarán en escenarios reales y condiciones adversas:

    • Pérdida de conexión durante operaciones críticas en una sede
    • Cierre inesperado de la aplicación con datos pendientes de sincronización
    • Ediciones concurrentes del mismo producto desde distintas sedes
    • Validación estricta del aislamiento entre tenants y entre sedes
    • Escenarios de transferencia: solicitud mientras sede origen se desconecta, aprobación con inventario insuficiente, etc.
    • Reportes consolidados con sedes parcialmente sincronizadas
### 11. Fuera de Alcance

    • Colaboración en tiempo real entre usuarios de distintas sedes
    • Sincronización instantánea multi-dispositivo dentro de una misma sede
    • Edición simultánea avanzada tipo Google Docs
    • Transferencias de inventario iniciadas desde una sede offline
    • Inventario compartido virtual entre múltiples sedes
    • Sincronización bidireccional automática de configuraciones estructurales (roles, permisos) desde las sedes hacia el backend
Este documento define qué hace el sistema y por qué, dejando las decisiones de implementación detalladas (algoritmos de sincronización, estructura de base de datos, protocolos de comunicación, etc.) para el Documento de Arquitectura.