-- =====================================================
-- Stocky v2 - Esquema SQLite (Base de Datos Local)
-- Versión: 2.0 (Arquitectura Híbrida Cloud-Edge)
-- Creado: 2026-02-09
-- Descripción: Base de datos local para aplicaciones
--              de escritorio (Tauri/Electron)
-- =====================================================

-- =====================================================
-- CONFIGURACIÓN DE SQLITE
-- =====================================================

PRAGMA journal_mode = WAL;              -- Write-Ahead Logging para concurrencia
PRAGMA synchronous = NORMAL;            -- Balance entre performance y durabilidad
PRAGMA foreign_keys = ON;               -- Integridad referencial
PRAGMA auto_vacuum = INCREMENTAL;       -- Gestión automática de espacio
PRAGMA cache_size = -64000;             -- 64MB de caché
PRAGMA temp_store = MEMORY;             -- Tablas temporales en memoria

-- =====================================================
-- 1. TABLA products
-- =====================================================

CREATE TABLE products (
    id TEXT PRIMARY KEY,
    sku TEXT NOT NULL,
    barcode TEXT,
    name TEXT NOT NULL,
    description TEXT,
    category TEXT,
    price REAL NOT NULL CHECK(price >= 0),
    cost REAL NOT NULL CHECK(cost >= 0),
    unit TEXT NOT NULL,
    sede_id TEXT NOT NULL,
    tenant_id TEXT NOT NULL,
    metadata TEXT,
    version INTEGER NOT NULL DEFAULT 1,
    last_modified_at INTEGER NOT NULL,
    synced_at INTEGER,
    sync_status TEXT DEFAULT 'PENDING',
    deleted INTEGER DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    CHECK (unit IN ('UNIT', 'KG', 'LITER', 'BOX', 'PACK', 'METER')),
    CHECK (sync_status IN ('PENDING', 'SYNCED', 'CONFLICT', 'FAILED'))
);

CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_barcode ON products(barcode) WHERE barcode IS NOT NULL;
CREATE INDEX idx_products_sync_status ON products(sync_status);
CREATE INDEX idx_products_last_modified ON products(last_modified_at DESC);

-- =====================================================
-- 2. TABLA inventory
-- =====================================================

CREATE TABLE inventory (
    id TEXT PRIMARY KEY,
    product_id TEXT NOT NULL,
    quantity REAL NOT NULL DEFAULT 0 CHECK(quantity >= 0),
    min_stock REAL NOT NULL DEFAULT 0,
    max_stock REAL NOT NULL DEFAULT 0,
    sede_id TEXT NOT NULL,
    version INTEGER NOT NULL DEFAULT 1,
    last_updated_at INTEGER NOT NULL,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX idx_inventory_product ON inventory(product_id);
CREATE INDEX idx_inventory_updated ON inventory(last_updated_at DESC);

-- =====================================================
-- 3. TABLA transactions
-- =====================================================

CREATE TABLE transactions (
    id TEXT PRIMARY KEY,
    type TEXT NOT NULL,
    product_id TEXT NOT NULL,
    quantity REAL NOT NULL,
    price REAL,
    reason TEXT,
    user_id TEXT NOT NULL,
    sede_id TEXT NOT NULL,
    transfer_id TEXT,
    metadata TEXT,
    client_timestamp INTEGER NOT NULL,
    server_timestamp INTEGER,
    synced_at INTEGER,
    sync_status TEXT DEFAULT 'PENDING',
    created_at INTEGER NOT NULL,
    FOREIGN KEY (product_id) REFERENCES products(id),
    CHECK (type IN ('SALE', 'PURCHASE', 'ADJUSTMENT', 'TRANSFER_IN', 'TRANSFER_OUT')),
    CHECK (sync_status IN ('PENDING', 'SYNCED', 'FAILED'))
);

CREATE INDEX idx_transactions_timestamp ON transactions(client_timestamp DESC);
CREATE INDEX idx_transactions_sync_status ON transactions(sync_status);
CREATE INDEX idx_transactions_product ON transactions(product_id);
CREATE INDEX idx_transactions_type ON transactions(type);
CREATE INDEX idx_transactions_synced ON transactions(synced_at);

-- =====================================================
-- 4. TABLA sync_queue
-- =====================================================

CREATE TABLE sync_queue (
    id TEXT PRIMARY KEY,
    operation TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    payload TEXT NOT NULL,
    timestamp INTEGER NOT NULL,
    retries INTEGER DEFAULT 0,
    status TEXT DEFAULT 'PENDING',
    error TEXT,
    created_at INTEGER NOT NULL,
    CHECK (operation IN ('CREATE', 'UPDATE', 'DELETE')),
    CHECK (entity_type IN ('products', 'inventory', 'transactions', 'users')),
    CHECK (status IN ('PENDING', 'IN_PROGRESS', 'COMPLETED', 'FAILED'))
);

CREATE INDEX idx_sync_queue_status ON sync_queue(status);
CREATE INDEX idx_sync_queue_timestamp ON sync_queue(timestamp ASC);
CREATE INDEX idx_sync_queue_entity ON sync_queue(entity_type, entity_id);

-- =====================================================
-- 5. TABLA users
-- =====================================================

CREATE TABLE users (
    id TEXT PRIMARY KEY,
    email TEXT NOT NULL,
    name TEXT NOT NULL,
    role TEXT NOT NULL,
    sede_id TEXT,
    tenant_id TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'ACTIVE',
    last_synced_at INTEGER,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    CHECK (role IN ('SUPER_ADMIN', 'TENANT_ADMIN', 'MANAGER', 'STAFF')),
    CHECK (status IN ('ACTIVE', 'INACTIVE', 'LOCKED'))
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

-- =====================================================
-- 6. TABLA auth_session
-- =====================================================

CREATE TABLE auth_session (
    id TEXT PRIMARY KEY,
    token TEXT NOT NULL,
    user_id TEXT NOT NULL,
    tenant_id TEXT NOT NULL,
    sede_id TEXT NOT NULL,
    role TEXT NOT NULL,
    expires_at INTEGER NOT NULL,
    last_refresh INTEGER,
    created_at INTEGER NOT NULL,
    CHECK (role IN ('SUPER_ADMIN', 'TENANT_ADMIN', 'MANAGER', 'STAFF'))
);

-- =====================================================
-- 7. TABLA config
-- =====================================================

CREATE TABLE config (
    id TEXT PRIMARY KEY,
    key TEXT NOT NULL UNIQUE,
    value TEXT NOT NULL,
    updated_at INTEGER NOT NULL
);

CREATE INDEX idx_config_key ON config(key);

-- =====================================================
-- TRIGGERS PARA INTEGRIDAD
-- =====================================================

-- Actualizar inventory al crear transacción
CREATE TRIGGER update_inventory_after_transaction
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
    UPDATE inventory
    SET quantity = quantity + NEW.quantity,
        last_updated_at = NEW.client_timestamp,
        updated_at = NEW.client_timestamp
    WHERE product_id = NEW.product_id;
END;

-- Agregar a sync_queue al modificar producto
CREATE TRIGGER sync_product_on_update
AFTER UPDATE ON products
FOR EACH ROW
WHEN NEW.sync_status = 'PENDING'
BEGIN
    INSERT INTO sync_queue (id, operation, entity_type, entity_id, payload, timestamp, created_at)
    VALUES (
        hex(randomblob(16)),
        'UPDATE',
        'products',
        NEW.id,
        json_object(
            'id', NEW.id,
            'sku', NEW.sku,
            'name', NEW.name,
            'price', NEW.price,
            'version', NEW.version,
            'last_modified_at', NEW.last_modified_at
        ),
        strftime('%s', 'now') * 1000,
        strftime('%s', 'now') * 1000
    );
END;

-- Agregar a sync_queue al crear producto
CREATE TRIGGER sync_product_on_insert
AFTER INSERT ON products
FOR EACH ROW
WHEN NEW.sync_status = 'PENDING'
BEGIN
    INSERT INTO sync_queue (id, operation, entity_type, entity_id, payload, timestamp, created_at)
    VALUES (
        hex(randomblob(16)),
        'CREATE',
        'products',
        NEW.id,
        json_object(
            'id', NEW.id,
            'sku', NEW.sku,
            'barcode', NEW.barcode,
            'name', NEW.name,
            'description', NEW.description,
            'category', NEW.category,
            'price', NEW.price,
            'cost', NEW.cost,
            'unit', NEW.unit,
            'metadata', NEW.metadata,
            'version', NEW.version
        ),
        strftime('%s', 'now') * 1000,
        strftime('%s', 'now') * 1000
    );
END;

-- Agregar a sync_queue al crear transacción
CREATE TRIGGER sync_transaction_on_insert
AFTER INSERT ON transactions
FOR EACH ROW
WHEN NEW.sync_status = 'PENDING'
BEGIN
    INSERT INTO sync_queue (id, operation, entity_type, entity_id, payload, timestamp, created_at)
    VALUES (
        hex(randomblob(16)),
        'CREATE',
        'transactions',
        NEW.id,
        json_object(
            'id', NEW.id,
            'type', NEW.type,
            'product_id', NEW.product_id,
            'quantity', NEW.quantity,
            'price', NEW.price,
            'reason', NEW.reason,
            'user_id', NEW.user_id,
            'sede_id', NEW.sede_id,
            'transfer_id', NEW.transfer_id,
            'metadata', NEW.metadata,
            'client_timestamp', NEW.client_timestamp
        ),
        strftime('%s', 'now') * 1000,
        strftime('%s', 'now') * 1000
    );
END;

-- =====================================================
-- INSERTAR CONFIGURACIÓN INICIAL
-- =====================================================

INSERT INTO config (id, key, value, updated_at) VALUES
    ('sede_id', 'sede_id', '""', strftime('%s', 'now') * 1000),
    ('tenant_id', 'tenant_id', '""', strftime('%s', 'now') * 1000),
    ('sede_name', 'sede_name', '""', strftime('%s', 'now') * 1000),
    ('last_pull_timestamp', 'last_pull_timestamp', '0', strftime('%s', 'now') * 1000),
    ('sync_interval_ms', 'sync_interval_ms', '300000', strftime('%s', 'now') * 1000),
    ('offline_mode', 'offline_mode', 'false', strftime('%s', 'now') * 1000),
    ('theme', 'theme', '"dark"', strftime('%s', 'now') * 1000),
    ('language', 'language', '"es"', strftime('%s', 'now') * 1000);

-- =====================================================
-- FIN DEL ESQUEMA
-- =====================================================
