-- =====================================================
-- Stocky - Esquema de Base de Datos PostgreSQL (Hub Backend)
-- Versión: 1.0
-- Creado: 2026-02-07
-- Descripción: Base de datos central hub para sistema 
--              de gestión de inventario multi-tenant
-- =====================================================

-- Habilitar extensión UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- 1. TABLA TENANTS
-- =====================================================
-- Representa cada organización/empresa que usa el sistema

CREATE TABLE tenants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    plan VARCHAR(50) NOT NULL CHECK (plan IN ('FREE', 'BASIC', 'PREMIUM', 'ENTERPRISE')),
    status VARCHAR(50) NOT NULL CHECK (status IN ('ACTIVE', 'SUSPENDED', 'CANCELLED')),
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE tenants IS 'Organizaciones que usan el sistema (multi-tenancy)';
COMMENT ON COLUMN tenants.plan IS 'Plan de suscripción: FREE | BASIC | PREMIUM | ENTERPRISE';
COMMENT ON COLUMN tenants.status IS 'Estado de la cuenta: ACTIVE | SUSPENDED | CANCELLED';
COMMENT ON COLUMN tenants.settings IS 'Configuraciones personalizadas (logo, colores, políticas de stock, etc.)';

-- =====================================================
-- 2. TABLA SEDES
-- =====================================================
-- Sucursales, tiendas o puntos de venta de cada tenant

CREATE TABLE sedes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) NOT NULL,
    address TEXT,
    status VARCHAR(50) NOT NULL CHECK (status IN ('ACTIVE', 'INACTIVE', 'MAINTENANCE')),
    last_sync_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_sedes_tenant FOREIGN KEY (tenant_id) 
        REFERENCES tenants(id) ON DELETE CASCADE,
    CONSTRAINT unique_code_per_tenant UNIQUE (tenant_id, code)
);

COMMENT ON TABLE sedes IS 'Sucursales/tiendas de cada tenant (cada una tiene su propia base de datos local)';
COMMENT ON COLUMN sedes.code IS 'Código corto único para identificación rápida (ej: TN-001)';
COMMENT ON COLUMN sedes.last_sync_at IS 'Timestamp de la última sincronización exitosa';
COMMENT ON COLUMN sedes.status IS 'Estado de la sede: ACTIVE | INACTIVE | MAINTENANCE';

-- =====================================================
-- 3. TABLA USERS
-- =====================================================
-- Usuarios del sistema con roles y permisos (RBAC)

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    sede_id UUID,
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('SUPER_ADMIN', 'TENANT_ADMIN', 'MANAGER', 'STAFF')),
    status VARCHAR(50) NOT NULL CHECK (status IN ('ACTIVE', 'INACTIVE', 'LOCKED')),
    last_login_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_users_tenant FOREIGN KEY (tenant_id) 
        REFERENCES tenants(id) ON DELETE CASCADE,
    CONSTRAINT fk_users_sede FOREIGN KEY (sede_id) 
        REFERENCES sedes(id) ON DELETE SET NULL,
    CONSTRAINT unique_email_per_tenant UNIQUE (tenant_id, email)
);

COMMENT ON TABLE users IS 'Usuarios del sistema con control de acceso basado en roles';
COMMENT ON COLUMN users.sede_id IS 'Sede asignada (nullable para TENANT_ADMIN que puede ver todas las sedes)';
COMMENT ON COLUMN users.password_hash IS 'Hash bcrypt de la contraseña (nunca almacenar en texto plano)';
COMMENT ON COLUMN users.role IS 'Rol del usuario: SUPER_ADMIN | TENANT_ADMIN | MANAGER | STAFF';

-- =====================================================
-- 4. TABLA PRODUCTS_CONSOLIDATED
-- =====================================================
-- Catálogo maestro de productos de cada tenant

CREATE TABLE products_consolidated (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    sku VARCHAR(100) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100),
    price DECIMAL(12, 2) NOT NULL DEFAULT 0,
    cost DECIMAL(12, 2) NOT NULL DEFAULT 0,
    unit VARCHAR(50) NOT NULL DEFAULT 'UNIT',
    metadata JSONB DEFAULT '{}',
    version INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_products_tenant FOREIGN KEY (tenant_id) 
        REFERENCES tenants(id) ON DELETE CASCADE,
    CONSTRAINT unique_sku_per_tenant UNIQUE (tenant_id, sku)
);

COMMENT ON TABLE products_consolidated IS 'Catálogo maestro de productos sincronizado desde todas las sedes';
COMMENT ON COLUMN products_consolidated.sku IS 'Código único del producto (ej: LAP-HP-001)';
COMMENT ON COLUMN products_consolidated.version IS 'Control de versión para resolución de conflictos (Last-Write-Wins)';
COMMENT ON COLUMN products_consolidated.unit IS 'Unidad de medida: UNIT | KG | LITER | BOX | etc.';
COMMENT ON COLUMN products_consolidated.metadata IS 'Datos flexibles (imágenes, especificaciones, códigos de barras, etc.)';

-- =====================================================
-- 5. TABLA INVENTORY_CONSOLIDATED
-- =====================================================
-- Vista consolidada del stock actual por producto por sede

CREATE TABLE inventory_consolidated (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    sede_id UUID NOT NULL,
    product_id UUID NOT NULL,
    quantity DECIMAL(12, 2) NOT NULL DEFAULT 0,
    min_stock DECIMAL(12, 2) DEFAULT 0,
    max_stock DECIMAL(12, 2),
    last_sync_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_inventory_tenant FOREIGN KEY (tenant_id) 
        REFERENCES tenants(id) ON DELETE CASCADE,
    CONSTRAINT fk_inventory_sede FOREIGN KEY (sede_id) 
        REFERENCES sedes(id) ON DELETE CASCADE,
    CONSTRAINT fk_inventory_product FOREIGN KEY (product_id) 
        REFERENCES products_consolidated(id) ON DELETE CASCADE,
    CONSTRAINT quantity_non_negative CHECK (quantity >= 0),
    CONSTRAINT unique_inventory_per_sede_product UNIQUE (sede_id, product_id)
);

COMMENT ON TABLE inventory_consolidated IS 'Vista consolidada de stock actualizada con cada sincronización';
COMMENT ON COLUMN inventory_consolidated.quantity IS 'Stock actual calculado desde TRANSACTIONS_LOG';
COMMENT ON COLUMN inventory_consolidated.min_stock IS 'Umbral de stock mínimo (alerta)';
COMMENT ON COLUMN inventory_consolidated.max_stock IS 'Umbral de stock máximo';
COMMENT ON COLUMN inventory_consolidated.last_sync_at IS 'Indica qué tan actualizado está este dato';

-- =====================================================
-- 6. TABLA TRANSACTIONS_LOG
-- =====================================================
-- Log inmutable (append-only) de todas las transacciones de inventario

CREATE TABLE transactions_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    sede_id UUID NOT NULL,
    product_id UUID NOT NULL,
    user_id UUID NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('IN', 'OUT', 'ADJUSTMENT', 'TRANSFER_IN', 'TRANSFER_OUT')),
    quantity DECIMAL(12, 2) NOT NULL,
    reason TEXT,
    transfer_id UUID,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    synced_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB DEFAULT '{}',
    
    CONSTRAINT fk_transactions_tenant FOREIGN KEY (tenant_id) 
        REFERENCES tenants(id) ON DELETE CASCADE,
    CONSTRAINT fk_transactions_sede FOREIGN KEY (sede_id) 
        REFERENCES sedes(id) ON DELETE CASCADE,
    CONSTRAINT fk_transactions_product FOREIGN KEY (product_id) 
        REFERENCES products_consolidated(id) ON DELETE CASCADE,
    CONSTRAINT fk_transactions_user FOREIGN KEY (user_id) 
        REFERENCES users(id) ON DELETE CASCADE
);

COMMENT ON TABLE transactions_log IS 'Log inmutable append-only de todas las transacciones de inventario';
COMMENT ON COLUMN transactions_log.type IS 'Tipo de transacción: IN | OUT | ADJUSTMENT | TRANSFER_IN | TRANSFER_OUT';
COMMENT ON COLUMN transactions_log.transfer_id IS 'Vincula transacciones que son parte de una transferencia entre sedes';
COMMENT ON COLUMN transactions_log.timestamp IS 'Cuándo ocurrió realmente la transacción (puede ser offline)';
COMMENT ON COLUMN transactions_log.synced_at IS 'Cuándo se sincronizó la transacción al backend';

-- =====================================================
-- 7. TABLA TRANSFERS
-- =====================================================
-- Gestión de transferencias de inventario entre sedes

CREATE TABLE transfers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    from_sede_id UUID NOT NULL,
    to_sede_id UUID NOT NULL,
    product_id UUID NOT NULL,
    requested_by UUID NOT NULL,
    approved_by UUID,
    quantity DECIMAL(12, 2) NOT NULL,
    status VARCHAR(50) NOT NULL CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'PROCESSING', 'COMPLETED', 'FAILED')),
    rejection_reason TEXT,
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    approved_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB DEFAULT '{}',
    
    CONSTRAINT fk_transfers_tenant FOREIGN KEY (tenant_id) 
        REFERENCES tenants(id) ON DELETE CASCADE,
    CONSTRAINT fk_transfers_from_sede FOREIGN KEY (from_sede_id) 
        REFERENCES sedes(id) ON DELETE CASCADE,
    CONSTRAINT fk_transfers_to_sede FOREIGN KEY (to_sede_id) 
        REFERENCES sedes(id) ON DELETE CASCADE,
    CONSTRAINT fk_transfers_product FOREIGN KEY (product_id) 
        REFERENCES products_consolidated(id) ON DELETE CASCADE,
    CONSTRAINT fk_transfers_requested_by FOREIGN KEY (requested_by) 
        REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_transfers_approved_by FOREIGN KEY (approved_by) 
        REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT different_sedes CHECK (from_sede_id != to_sede_id),
    CONSTRAINT quantity_positive CHECK (quantity > 0)
);

COMMENT ON TABLE transfers IS 'Transferencias de inventario entre sedes que requieren coordinación y aprobación';
COMMENT ON COLUMN transfers.status IS 'Estado de transferencia: PENDING → APPROVED → PROCESSING → COMPLETED (o REJECTED/FAILED)';
COMMENT ON COLUMN transfers.approved_by IS 'Usuario que aprobó (usualmente Manager de la sede origen)';
COMMENT ON COLUMN transfers.rejection_reason IS 'Requerido si status = REJECTED';

-- =====================================================
-- 8. TABLA AUDIT_LOGS
-- =====================================================
-- Registro inmutable de todas las acciones importantes del sistema

CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    user_id UUID NOT NULL,
    sede_id UUID,
    action VARCHAR(50) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID,
    metadata JSONB DEFAULT '{}',
    ip_address VARCHAR(45),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_audit_tenant FOREIGN KEY (tenant_id) 
        REFERENCES tenants(id) ON DELETE CASCADE,
    CONSTRAINT fk_audit_user FOREIGN KEY (user_id) 
        REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_audit_sede FOREIGN KEY (sede_id) 
        REFERENCES sedes(id) ON DELETE SET NULL
);

COMMENT ON TABLE audit_logs IS 'Registro de auditoría inmutable de todas las acciones importantes del sistema';
COMMENT ON COLUMN audit_logs.action IS 'Tipo de acción: CREATE | UPDATE | DELETE | TRANSFER | SYNC';
COMMENT ON COLUMN audit_logs.entity_type IS 'Entidad afectada: PRODUCT | INVENTORY | USER | TRANSFER | etc.';
COMMENT ON COLUMN audit_logs.metadata IS 'Detalles de la acción (valores antes/después, razón, etc.)';
COMMENT ON COLUMN audit_logs.ip_address IS 'IP del cliente para seguridad y detección de accesos sospechosos';

-- =====================================================
-- ÍNDICES PARA RENDIMIENTO
-- =====================================================

-- Índices de multi-tenancy (todas las queries filtran por tenant)
CREATE INDEX idx_sedes_tenant ON sedes(tenant_id);
CREATE INDEX idx_users_tenant ON users(tenant_id);
CREATE INDEX idx_products_tenant ON products_consolidated(tenant_id);
CREATE INDEX idx_inventory_tenant_sede ON inventory_consolidated(tenant_id, sede_id);
CREATE INDEX idx_transactions_tenant_sede ON transactions_log(tenant_id, sede_id);
CREATE INDEX idx_transfers_tenant ON transfers(tenant_id);
CREATE INDEX idx_audit_tenant ON audit_logs(tenant_id);

-- Búsquedas frecuentes
CREATE INDEX idx_products_sku ON products_consolidated(tenant_id, sku);
CREATE INDEX idx_users_email ON users(tenant_id, email);
CREATE INDEX idx_inventory_product ON inventory_consolidated(product_id);
CREATE INDEX idx_transactions_timestamp ON transactions_log(timestamp DESC);
CREATE INDEX idx_transfers_status ON transfers(status);

-- Sincronización
CREATE INDEX idx_sedes_last_sync ON sedes(last_sync_at);
CREATE INDEX idx_transactions_synced ON transactions_log(synced_at);
CREATE INDEX idx_inventory_last_sync ON inventory_consolidated(last_sync_at);

-- Auditoría
CREATE INDEX idx_audit_user ON audit_logs(user_id);
CREATE INDEX idx_audit_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_timestamp ON audit_logs(timestamp DESC);

-- Relaciones de transferencias
CREATE INDEX idx_transfers_from_sede ON transfers(from_sede_id);
CREATE INDEX idx_transfers_to_sede ON transfers(to_sede_id);
CREATE INDEX idx_transfers_product ON transfers(product_id);
CREATE INDEX idx_transactions_transfer ON transactions_log(transfer_id) WHERE transfer_id IS NOT NULL;

-- =====================================================
-- TRIGGERS PARA ACTUALIZACIÓN AUTOMÁTICA DE TIMESTAMPS
-- =====================================================

-- Función para actualizar el timestamp updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger a tablas con updated_at
CREATE TRIGGER update_tenants_updated_at BEFORE UPDATE ON tenants
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sedes_updated_at BEFORE UPDATE ON sedes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products_consolidated
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_inventory_updated_at BEFORE UPDATE ON inventory_consolidated
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- ROW LEVEL SECURITY (RLS) PARA MULTI-TENANCY
-- =====================================================

-- Habilitar RLS en todas las tablas
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE sedes ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE products_consolidated ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_consolidated ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE transfers ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Nota: Las políticas RLS deben crearse basadas en el mecanismo de
-- autenticación de tu aplicación. Ejemplo de política para aislamiento de tenant:
--
-- CREATE POLICY tenant_isolation_policy ON sedes
--     USING (tenant_id = current_setting('app.current_tenant_id')::uuid);
--
-- Esto requiere configurar el tenant_id en la sesión:
-- SET app.current_tenant_id = '<tenant-uuid>';

-- =====================================================
-- FOREIGN KEYS ADICIONALES
-- =====================================================
-- Agregar foreign key para transfer_id después de crear todas las tablas
-- (evita problemas de dependencias circulares)

ALTER TABLE transactions_log 
    ADD CONSTRAINT fk_transactions_transfer 
    FOREIGN KEY (transfer_id) REFERENCES transfers(id) ON DELETE SET NULL;

COMMENT ON CONSTRAINT fk_transactions_transfer ON transactions_log IS 
    'Vincula transacciones con transferencias entre sedes (nullable porque no todas las transacciones son transferencias)';

-- =====================================================
-- QUERIES DE EJEMPLO (COMENTADAS)
-- =====================================================

-- Reporte consolidado de inventario
/*
SELECT 
  p.name,
  p.sku,
  s.name as sede_name,
  i.quantity,
  i.last_sync_at,
  CASE 
    WHEN i.last_sync_at < NOW() - INTERVAL '2 hours' THEN 'DESACTUALIZADO'
    ELSE 'ACTUALIZADO'
  END as sync_status
FROM inventory_consolidated i
JOIN products_consolidated p ON i.product_id = p.id
JOIN sedes s ON i.sede_id = s.id
WHERE i.tenant_id = :tenantId
ORDER BY p.name, s.name;
*/

-- Total de stock por producto (todas las sedes)
/*
SELECT 
  p.id,
  p.name,
  p.sku,
  SUM(i.quantity) as total_quantity,
  COUNT(DISTINCT i.sede_id) as sedes_with_stock,
  MAX(i.last_sync_at) as last_sync
FROM products_consolidated p
LEFT JOIN inventory_consolidated i ON p.id = i.product_id
WHERE p.tenant_id = :tenantId
GROUP BY p.id, p.name, p.sku
ORDER BY total_quantity DESC;
*/

-- Transferencias pendientes de aprobación
/*
SELECT 
  t.id,
  t.quantity,
  p.name as product_name,
  s_from.name as from_sede,
  s_to.name as to_sede,
  u.email as requested_by,
  t.requested_at
FROM transfers t
JOIN products_consolidated p ON t.product_id = p.id
JOIN sedes s_from ON t.from_sede_id = s_from.id
JOIN sedes s_to ON t.to_sede_id = s_to.id
JOIN users u ON t.requested_by = u.id
WHERE t.tenant_id = :tenantId
  AND t.status = 'PENDING'
ORDER BY t.requested_at ASC;
*/

-- =====================================================
-- FIN DEL ESQUEMA
-- =====================================================
