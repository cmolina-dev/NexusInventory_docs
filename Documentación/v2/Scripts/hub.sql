-- =====================================================
-- Stocky v2 - Esquema de Base de Datos PostgreSQL (Hub Backend)
-- Versión: 2.0 (Arquitectura Híbrida Cloud-Edge)
-- Creado: 2026-02-09
-- Descripción: Base de datos central hub para sistema 
--              de gestión de inventario multi-tenant
--              con sincronización robusta
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
    email VARCHAR(255) NOT NULL UNIQUE,
    plan VARCHAR(50) NOT NULL CHECK (plan IN ('FREE', 'BASIC', 'PREMIUM', 'ENTERPRISE')),
    status VARCHAR(50) NOT NULL CHECK (status IN ('ACTIVE', 'SUSPENDED', 'CANCELLED')),
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE tenants IS 'Organizaciones que usan el sistema (multi-tenancy)';
COMMENT ON COLUMN tenants.plan IS 'Plan de suscripción: FREE | BASIC | PREMIUM | ENTERPRISE';
COMMENT ON COLUMN tenants.status IS 'Estado de la cuenta: ACTIVE | SUSPENDED | CANCELLED';
COMMENT ON COLUMN tenants.settings IS 'Configuraciones personalizadas (logo, colores, políticas de stock, timezone, currency, etc.)';

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
    is_online BOOLEAN DEFAULT FALSE,
    last_sync_at TIMESTAMP WITH TIME ZONE,
    last_ping_at TIMESTAMP WITH TIME ZONE,
    sync_version INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_sedes_tenant FOREIGN KEY (tenant_id) 
        REFERENCES tenants(id) ON DELETE CASCADE,
    CONSTRAINT unique_code_per_tenant UNIQUE (tenant_id, code)
);

COMMENT ON TABLE sedes IS 'Sucursales/tiendas de cada tenant (cada una tiene su propia aplicación de escritorio con SQLite)';
COMMENT ON COLUMN sedes.code IS 'Código corto único para identificación rápida (ej: TS-CEN)';
COMMENT ON COLUMN sedes.is_online IS 'Estado de conectividad actualizado por heartbeat cada 30s';
COMMENT ON COLUMN sedes.last_sync_at IS 'Timestamp de la última sincronización exitosa';
COMMENT ON COLUMN sedes.last_ping_at IS 'Último heartbeat recibido. Si > 2 min, se considera offline';
COMMENT ON COLUMN sedes.sync_version IS 'Número incremental para detectar cambios pendientes';

-- =====================================================
-- 3. TABLA ACTIVATION_CODES
-- =====================================================
-- Códigos de activación de un solo uso para apps de escritorio

CREATE TABLE activation_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sede_id UUID NOT NULL,
    code VARCHAR(6) NOT NULL UNIQUE,
    is_used BOOLEAN DEFAULT FALSE,
    used_at TIMESTAMP WITH TIME ZONE,
    client_info JSONB,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_activation_sede FOREIGN KEY (sede_id)
        REFERENCES sedes(id) ON DELETE CASCADE
);

COMMENT ON TABLE activation_codes IS 'Códigos de activación de un solo uso para activar aplicaciones de escritorio';
COMMENT ON COLUMN activation_codes.code IS 'Código alfanumérico de 6 caracteres';
COMMENT ON COLUMN activation_codes.is_used IS 'Una vez usado, no se puede reutilizar';
COMMENT ON COLUMN activation_codes.expires_at IS 'Previene uso de códigos antiguos (ej: 7 días)';
COMMENT ON COLUMN activation_codes.client_info IS 'JSON con información del dispositivo activado';

-- =====================================================
-- 4. TABLA USERS
-- =====================================================
-- Usuarios del sistema con roles y permisos (RBAC)

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    sede_id UUID,
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
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
-- 5. TABLA PRODUCTS
-- =====================================================
-- Catálogo maestro de productos de cada tenant (fuente de verdad)

CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    sku VARCHAR(100) NOT NULL,
    barcode VARCHAR(100),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100),
    price DECIMAL(12, 2) NOT NULL DEFAULT 0,
    cost DECIMAL(12, 2) NOT NULL DEFAULT 0,
    unit VARCHAR(50) NOT NULL DEFAULT 'UNIT',
    metadata JSONB DEFAULT '{}',
    version INTEGER NOT NULL DEFAULT 1,
    last_modified_by UUID,
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_products_tenant FOREIGN KEY (tenant_id) 
        REFERENCES tenants(id) ON DELETE CASCADE,
    CONSTRAINT fk_products_modified_by FOREIGN KEY (last_modified_by)
        REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT unique_sku_per_tenant UNIQUE (tenant_id, sku)
);

COMMENT ON TABLE products IS 'Catálogo maestro de productos - fuente de verdad global';
COMMENT ON COLUMN products.sku IS 'Código único del producto (ej: LAP-HP-001)';
COMMENT ON COLUMN products.barcode IS 'Código de barras (opcional, puede ser null)';
COMMENT ON COLUMN products.version IS 'Control de versión para resolución de conflictos (Last-Write-Wins)';
COMMENT ON COLUMN products.last_modified_by IS 'Usuario que hizo la última modificación';
COMMENT ON COLUMN products.last_modified_at IS 'Timestamp del servidor (autoritativo)';
COMMENT ON COLUMN products.unit IS 'Unidad de medida: UNIT | KG | LITER | BOX | etc.';
COMMENT ON COLUMN products.metadata IS 'Datos flexibles (imágenes, especificaciones, supplier, etc.)';

-- =====================================================
-- 6. TABLA INVENTORY
-- =====================================================
-- Stock actual por producto por sede (fuente de verdad)

CREATE TABLE inventory (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    sede_id UUID NOT NULL,
    product_id UUID NOT NULL,
    quantity DECIMAL(12, 2) NOT NULL DEFAULT 0,
    min_stock DECIMAL(12, 2) DEFAULT 0,
    max_stock DECIMAL(12, 2),
    version INTEGER NOT NULL DEFAULT 1,
    last_updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_inventory_tenant FOREIGN KEY (tenant_id) 
        REFERENCES tenants(id) ON DELETE CASCADE,
    CONSTRAINT fk_inventory_sede FOREIGN KEY (sede_id) 
        REFERENCES sedes(id) ON DELETE CASCADE,
    CONSTRAINT fk_inventory_product FOREIGN KEY (product_id) 
        REFERENCES products(id) ON DELETE CASCADE,
    CONSTRAINT quantity_non_negative CHECK (quantity >= 0),
    CONSTRAINT unique_inventory_per_sede_product UNIQUE (sede_id, product_id)
);

COMMENT ON TABLE inventory IS 'Stock actual por producto por sede - fuente de verdad global';
COMMENT ON COLUMN inventory.quantity IS 'Stock actual (no puede ser negativo)';
COMMENT ON COLUMN inventory.version IS 'Para detectar conflictos durante sincronización';
COMMENT ON COLUMN inventory.min_stock IS 'Umbral de stock mínimo (alerta)';
COMMENT ON COLUMN inventory.max_stock IS 'Umbral de stock máximo';

-- =====================================================
-- 7. TABLA TRANSACTIONS
-- =====================================================
-- Log inmutable (append-only) de todas las transacciones de inventario

CREATE TABLE transactions (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    sede_id UUID NOT NULL,
    product_id UUID NOT NULL,
    user_id UUID NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('SALE', 'PURCHASE', 'ADJUSTMENT', 'TRANSFER_IN', 'TRANSFER_OUT')),
    quantity DECIMAL(12, 2) NOT NULL,
    price DECIMAL(12, 2),
    reason TEXT,
    transfer_id UUID,
    metadata JSONB DEFAULT '{}',
    client_timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    server_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    synced_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_transactions_tenant FOREIGN KEY (tenant_id) 
        REFERENCES tenants(id) ON DELETE CASCADE,
    CONSTRAINT fk_transactions_sede FOREIGN KEY (sede_id) 
        REFERENCES sedes(id) ON DELETE CASCADE,
    CONSTRAINT fk_transactions_product FOREIGN KEY (product_id) 
        REFERENCES products(id) ON DELETE CASCADE,
    CONSTRAINT fk_transactions_user FOREIGN KEY (user_id) 
        REFERENCES users(id) ON DELETE CASCADE
);

COMMENT ON TABLE transactions IS 'Log inmutable append-only de todas las transacciones de inventario';
COMMENT ON COLUMN transactions.id IS 'UUID generado en el cliente para garantizar unicidad offline';
COMMENT ON COLUMN transactions.type IS 'Tipo de transacción: SALE | PURCHASE | ADJUSTMENT | TRANSFER_IN | TRANSFER_OUT';
COMMENT ON COLUMN transactions.transfer_id IS 'Vincula transacciones que son parte de una transferencia entre sedes';
COMMENT ON COLUMN transactions.client_timestamp IS 'Cuándo ocurrió realmente la transacción (puede ser offline)';
COMMENT ON COLUMN transactions.server_timestamp IS 'Cuándo llegó al backend (autoritativo para ordenamiento)';
COMMENT ON COLUMN transactions.synced_at IS 'Cuándo se sincronizó la transacción al backend';

-- =====================================================
-- 8. TABLA TRANSFERS
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
    failed_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_transfers_tenant FOREIGN KEY (tenant_id) 
        REFERENCES tenants(id) ON DELETE CASCADE,
    CONSTRAINT fk_transfers_from_sede FOREIGN KEY (from_sede_id) 
        REFERENCES sedes(id) ON DELETE CASCADE,
    CONSTRAINT fk_transfers_to_sede FOREIGN KEY (to_sede_id) 
        REFERENCES sedes(id) ON DELETE CASCADE,
    CONSTRAINT fk_transfers_product FOREIGN KEY (product_id) 
        REFERENCES products(id) ON DELETE CASCADE,
    CONSTRAINT fk_transfers_requested_by FOREIGN KEY (requested_by) 
        REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_transfers_approved_by FOREIGN KEY (approved_by) 
        REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT different_sedes CHECK (from_sede_id != to_sede_id),
    CONSTRAINT quantity_positive CHECK (quantity > 0)
);

COMMENT ON TABLE transfers IS 'Transferencias de inventario entre sedes que requieren coordinación y aprobación';
COMMENT ON COLUMN transfers.status IS 'Estado: PENDING → APPROVED → PROCESSING → COMPLETED (o REJECTED/FAILED)';
COMMENT ON COLUMN transfers.approved_by IS 'Usuario que aprobó (usualmente Manager de la sede origen)';
COMMENT ON COLUMN transfers.failed_at IS 'Timestamp si falló la ejecución';

-- =====================================================
-- 9. TABLA AUDIT_LOGS
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
    before_data JSONB,
    after_data JSONB,
    ip_address VARCHAR(45),
    user_agent TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_audit_tenant FOREIGN KEY (tenant_id) 
        REFERENCES tenants(id) ON DELETE CASCADE,
    CONSTRAINT fk_audit_user FOREIGN KEY (user_id) 
        REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_audit_sede FOREIGN KEY (sede_id) 
        REFERENCES sedes(id) ON DELETE SET NULL
);

COMMENT ON TABLE audit_logs IS 'Registro de auditoría inmutable de todas las acciones importantes del sistema';
COMMENT ON COLUMN audit_logs.action IS 'Tipo de acción: CREATE | UPDATE | DELETE | TRANSFER | SYNC | LOGIN | LOGOUT';
COMMENT ON COLUMN audit_logs.entity_type IS 'Entidad afectada: PRODUCT | INVENTORY | USER | TRANSFER | etc.';
COMMENT ON COLUMN audit_logs.before_data IS 'Estado antes del cambio (para UPDATE)';
COMMENT ON COLUMN audit_logs.after_data IS 'Estado después del cambio (para UPDATE)';
COMMENT ON COLUMN audit_logs.ip_address IS 'IP del cliente para seguridad';
COMMENT ON COLUMN audit_logs.user_agent IS 'User agent del navegador/app';

-- =====================================================
-- 10. TABLA SYNC_LOGS
-- =====================================================
-- Registro de operaciones de sincronización

CREATE TABLE sync_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    sede_id UUID NOT NULL,
    direction VARCHAR(10) NOT NULL CHECK (direction IN ('PUSH', 'PULL')),
    entity_type VARCHAR(50) NOT NULL,
    records_count INTEGER NOT NULL DEFAULT 0,
    success BOOLEAN NOT NULL DEFAULT TRUE,
    error_message TEXT,
    conflicts_detected INTEGER DEFAULT 0,
    conflicts_resolved INTEGER DEFAULT 0,
    duration_ms BIGINT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_sync_tenant FOREIGN KEY (tenant_id)
        REFERENCES tenants(id) ON DELETE CASCADE,
    CONSTRAINT fk_sync_sede FOREIGN KEY (sede_id)
        REFERENCES sedes(id) ON DELETE CASCADE
);

COMMENT ON TABLE sync_logs IS 'Registro de operaciones de sincronización para diagnóstico y monitoreo';
COMMENT ON COLUMN sync_logs.direction IS 'PUSH (sede→nube) | PULL (nube→sede)';
COMMENT ON COLUMN sync_logs.conflicts_detected IS 'Número de conflictos detectados';
COMMENT ON COLUMN sync_logs.conflicts_resolved IS 'Número de conflictos resueltos';
COMMENT ON COLUMN sync_logs.duration_ms IS 'Duración de la operación en milisegundos';

-- =====================================================
-- ÍNDICES PARA RENDIMIENTO
-- =====================================================

-- Índices de multi-tenancy (todas las queries filtran por tenant)
CREATE INDEX idx_sedes_tenant ON sedes(tenant_id);
CREATE INDEX idx_users_tenant ON users(tenant_id);
CREATE INDEX idx_products_tenant ON products(tenant_id);
CREATE INDEX idx_inventory_tenant_sede ON inventory(tenant_id, sede_id);
CREATE INDEX idx_transactions_tenant_sede ON transactions(tenant_id, sede_id);
CREATE INDEX idx_transfers_tenant ON transfers(tenant_id);
CREATE INDEX idx_audit_tenant ON audit_logs(tenant_id);
CREATE INDEX idx_sync_logs_tenant ON sync_logs(tenant_id);

-- Búsquedas frecuentes
CREATE INDEX idx_products_sku ON products(tenant_id, sku);
CREATE INDEX idx_products_barcode ON products(barcode) WHERE barcode IS NOT NULL;
CREATE INDEX idx_users_email ON users(tenant_id, email);
CREATE INDEX idx_inventory_product ON inventory(product_id);
CREATE INDEX idx_transactions_timestamp ON transactions(server_timestamp DESC);
CREATE INDEX idx_transfers_status ON transfers(status);

-- Sincronización (crítico para performance)
CREATE INDEX idx_sedes_last_sync ON sedes(last_sync_at);
CREATE INDEX idx_sedes_last_ping ON sedes(last_ping_at);
CREATE INDEX idx_sedes_is_online ON sedes(is_online);
CREATE INDEX idx_transactions_synced ON transactions(sede_id, synced_at);
CREATE INDEX idx_inventory_updated ON inventory(sede_id, last_updated_at DESC);
CREATE INDEX idx_products_modified ON products(tenant_id, last_modified_at DESC);

-- Activation codes
CREATE INDEX idx_activation_code ON activation_codes(code);
CREATE INDEX idx_activation_sede ON activation_codes(sede_id);
CREATE INDEX idx_activation_is_used ON activation_codes(is_used);

-- Auditoría
CREATE INDEX idx_audit_user ON audit_logs(user_id);
CREATE INDEX idx_audit_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_timestamp ON audit_logs(timestamp DESC);

-- Sync logs
CREATE INDEX idx_sync_logs_sede ON sync_logs(sede_id);
CREATE INDEX idx_sync_logs_timestamp ON sync_logs(timestamp DESC);
CREATE INDEX idx_sync_logs_success ON sync_logs(success);

-- Relaciones de transferencias
CREATE INDEX idx_transfers_from_sede ON transfers(from_sede_id);
CREATE INDEX idx_transfers_to_sede ON transfers(to_sede_id);
CREATE INDEX idx_transfers_product ON transfers(product_id);
CREATE INDEX idx_transactions_transfer ON transactions(transfer_id) WHERE transfer_id IS NOT NULL;

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

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_inventory_updated_at BEFORE UPDATE ON inventory
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_transfers_updated_at BEFORE UPDATE ON transfers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- ROW LEVEL SECURITY (RLS) PARA MULTI-TENANCY
-- =====================================================

-- Habilitar RLS en todas las tablas
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE sedes ENABLE ROW LEVEL SECURITY;
ALTER TABLE activation_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE transfers ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE sync_logs ENABLE ROW LEVEL SECURITY;

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

ALTER TABLE transactions 
    ADD CONSTRAINT fk_transactions_transfer 
    FOREIGN KEY (transfer_id) REFERENCES transfers(id) ON DELETE SET NULL;

COMMENT ON CONSTRAINT fk_transactions_transfer ON transactions IS 
    'Vincula transacciones con transferencias entre sedes (nullable porque no todas las transacciones son transferencias)';

-- =====================================================
-- FIN DEL ESQUEMA
-- =====================================================
