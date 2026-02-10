-- =====================================================
-- Stocky v2 - Script de Datos de Prueba (Seed Data Local)
-- Versión: 2.0
-- Creado: 2026-02-09
-- Descripción: Datos de prueba para SQLite local
--              (Simula TechStore Centro)
-- =====================================================

-- IMPORTANTE: Este script asume que ya se ejecutó local.sql

-- =====================================================
-- LIMPIAR DATOS EXISTENTES (OPCIONAL - COMENTADO)
-- =====================================================

/*
DELETE FROM sync_queue;
DELETE FROM transactions;
DELETE FROM inventory;
DELETE FROM products;
DELETE FROM users;
DELETE FROM auth_session;
-- No eliminar config ya que tiene valores iniciales importantes
*/

-- =====================================================
-- CONFIGURACIÓN DE LA SEDE
-- =====================================================

-- Actualizar configuración con datos de TechStore Centro
UPDATE config SET value = '"11111111-1111-1111-1111-111111111111"' WHERE key = 'tenant_id';
UPDATE config SET value = '"a1111111-1111-1111-1111-111111111111"' WHERE key = 'sede_id';
UPDATE config SET value = '"TechStore Centro"' WHERE key = 'sede_name';

-- =====================================================
-- 1. USERS (Usuarios Sincronizados)
-- =====================================================

INSERT INTO users (id, email, name, role, sede_id, tenant_id, status, last_synced_at, created_at, updated_at) VALUES
-- Manager de esta sede
('u1111111-1111-1111-1111-111111111112', 'manager.centro@techstore.com', 'María Gerente Centro', 'MANAGER', 'a1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'ACTIVE', strftime('%s', 'now') * 1000, strftime('%s', 'now') * 1000, strftime('%s', 'now') * 1000),

-- Staff de esta sede
('u1111111-1111-1111-1111-111111111113', 'vendedor1.centro@techstore.com', 'Juan Vendedor', 'STAFF', 'a1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'ACTIVE', strftime('%s', 'now') * 1000, strftime('%s', 'now') * 1000, strftime('%s', 'now') * 1000);

-- =====================================================
-- 2. AUTH_SESSION (Sesión Actual)
-- =====================================================

-- Sesión del vendedor actual
INSERT INTO auth_session (id, token, user_id, tenant_id, sede_id, role, expires_at, last_refresh, created_at) VALUES
('session-001', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...', 'u1111111-1111-1111-1111-111111111113', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'STAFF', (strftime('%s', 'now') + 86400) * 1000, strftime('%s', 'now') * 1000, strftime('%s', 'now') * 1000);

-- =====================================================
-- 3. PRODUCTS (Catálogo Local)
-- =====================================================

INSERT INTO products (id, sku, barcode, name, description, category, price, cost, unit, sede_id, tenant_id, metadata, version, last_modified_at, synced_at, sync_status, deleted, created_at, updated_at) VALUES
-- Laptops
('p1111111-1111-1111-1111-111111111111', 'LAP-HP-001', '7501234567890', 'Laptop HP Pavilion 15', 'Laptop HP Pavilion 15.6", Intel i5, 8GB RAM, 256GB SSD', 'Laptops', 2500000.00, 1800000.00, 'UNIT', 'a1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 
 '{"brand": "HP", "warranty": "12 months", "images": ["laptop-hp-001.jpg"], "supplier": "HP Colombia"}', 3, strftime('%s', 'now', '-2 days') * 1000, strftime('%s', 'now', '-2 days') * 1000, 'SYNCED', 0, strftime('%s', 'now', '-6 months') * 1000, strftime('%s', 'now', '-2 days') * 1000),

('p1111111-1111-1111-1111-111111111112', 'LAP-DEL-001', '7501234567891', 'Laptop Dell Inspiron 14', 'Laptop Dell Inspiron 14", Intel i7, 16GB RAM, 512GB SSD', 'Laptops', 3200000.00, 2400000.00, 'UNIT', 'a1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111',
 '{"brand": "Dell", "warranty": "12 months", "images": ["laptop-dell-001.jpg"], "supplier": "Dell Colombia"}', 1, strftime('%s', 'now', '-6 months') * 1000, strftime('%s', 'now', '-6 months') * 1000, 'SYNCED', 0, strftime('%s', 'now', '-6 months') * 1000, strftime('%s', 'now', '-6 months') * 1000),

-- Accesorios
('p1111111-1111-1111-1111-111111111113', 'MOU-LOG-001', '7501234567892', 'Mouse Logitech MX Master 3', 'Mouse inalámbrico ergonómico Logitech MX Master 3', 'Accesorios', 350000.00, 220000.00, 'UNIT', 'a1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111',
 '{"brand": "Logitech", "warranty": "24 months", "wireless": true}', 1, strftime('%s', 'now', '-5 months') * 1000, strftime('%s', 'now', '-5 months') * 1000, 'SYNCED', 0, strftime('%s', 'now', '-5 months') * 1000, strftime('%s', 'now', '-5 months') * 1000),

('p1111111-1111-1111-1111-111111111114', 'KEY-COR-001', '7501234567893', 'Teclado Corsair K70', 'Teclado mecánico RGB Corsair K70', 'Accesorios', 450000.00, 300000.00, 'UNIT', 'a1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111',
 '{"brand": "Corsair", "warranty": "24 months", "mechanical": true, "rgb": true}', 2, strftime('%s', 'now', '-1 month') * 1000, strftime('%s', 'now', '-1 month') * 1000, 'SYNCED', 0, strftime('%s', 'now', '-5 months') * 1000, strftime('%s', 'now', '-1 month') * 1000),

-- Monitores
('p1111111-1111-1111-1111-111111111115', 'MON-SAM-001', '7501234567894', 'Monitor Samsung 27" 4K', 'Monitor Samsung 27 pulgadas, resolución 4K UHD', 'Monitores', 1200000.00, 850000.00, 'UNIT', 'a1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111',
 '{"brand": "Samsung", "warranty": "36 months", "resolution": "3840x2160"}', 1, strftime('%s', 'now', '-4 months') * 1000, strftime('%s', 'now', '-4 months') * 1000, 'SYNCED', 0, strftime('%s', 'now', '-4 months') * 1000, strftime('%s', 'now', '-4 months') * 1000);

-- =====================================================
-- 4. INVENTORY (Stock Actual)
-- =====================================================

INSERT INTO inventory (id, product_id, quantity, min_stock, max_stock, sede_id, version, last_updated_at, created_at, updated_at) VALUES
('i1111111-1111-1111-1111-111111111111', 'p1111111-1111-1111-1111-111111111111', 15, 5, 30, 'a1111111-1111-1111-1111-111111111111', 5, strftime('%s', 'now', '-5 minutes') * 1000, strftime('%s', 'now', '-6 months') * 1000, strftime('%s', 'now', '-5 minutes') * 1000),

('i1111111-1111-1111-1111-111111111112', 'p1111111-1111-1111-1111-111111111112', 8, 3, 20, 'a1111111-1111-1111-1111-111111111111', 3, strftime('%s', 'now', '-5 minutes') * 1000, strftime('%s', 'now', '-6 months') * 1000, strftime('%s', 'now', '-5 minutes') * 1000),

('i1111111-1111-1111-1111-111111111113', 'p1111111-1111-1111-1111-111111111113', 45, 10, 100, 'a1111111-1111-1111-1111-111111111111', 8, strftime('%s', 'now', '-5 minutes') * 1000, strftime('%s', 'now', '-5 months') * 1000, strftime('%s', 'now', '-5 minutes') * 1000),

('i1111111-1111-1111-1111-111111111114', 'p1111111-1111-1111-1111-111111111114', 32, 10, 80, 'a1111111-1111-1111-1111-111111111111', 4, strftime('%s', 'now', '-5 minutes') * 1000, strftime('%s', 'now', '-5 months') * 1000, strftime('%s', 'now', '-5 minutes') * 1000),

('i1111111-1111-1111-1111-111111111115', 'p1111111-1111-1111-1111-111111111115', 12, 5, 25, 'a1111111-1111-1111-1111-111111111111', 2, strftime('%s', 'now', '-5 minutes') * 1000, strftime('%s', 'now', '-4 months') * 1000, strftime('%s', 'now', '-5 minutes') * 1000);

-- =====================================================
-- 5. TRANSACTIONS (Historial de Transacciones)
-- =====================================================

-- Nota: Los triggers automáticamente actualizarán inventory y sync_queue

-- Entradas de inventario inicial
INSERT INTO transactions (id, type, product_id, quantity, price, reason, user_id, sede_id, transfer_id, metadata, client_timestamp, server_timestamp, synced_at, sync_status, created_at) VALUES
('t1111111-1111-1111-1111-111111111111', 'PURCHASE', 'p1111111-1111-1111-1111-111111111111', 20, NULL, 'Compra inicial de inventario', 'u1111111-1111-1111-1111-111111111112', 'a1111111-1111-1111-1111-111111111111', NULL, NULL, strftime('%s', 'now', '-5 days') * 1000, strftime('%s', 'now', '-5 days') * 1000, strftime('%s', 'now', '-5 days') * 1000, 'SYNCED', strftime('%s', 'now', '-5 days') * 1000),

('t1111111-1111-1111-1111-111111111112', 'PURCHASE', 'p1111111-1111-1111-1111-111111111113', 50, NULL, 'Compra inicial de inventario', 'u1111111-1111-1111-1111-111111111112', 'a1111111-1111-1111-1111-111111111111', NULL, NULL, strftime('%s', 'now', '-5 days') * 1000, strftime('%s', 'now', '-5 days') * 1000, strftime('%s', 'now', '-5 days') * 1000, 'SYNCED', strftime('%s', 'now', '-5 days') * 1000),

('t1111111-1111-1111-1111-111111111113', 'PURCHASE', 'p1111111-1111-1111-1111-111111111114', 40, NULL, 'Compra inicial de inventario', 'u1111111-1111-1111-1111-111111111112', 'a1111111-1111-1111-1111-111111111111', NULL, NULL, strftime('%s', 'now', '-5 days') * 1000, strftime('%s', 'now', '-5 days') * 1000, strftime('%s', 'now', '-5 days') * 1000, 'SYNCED', strftime('%s', 'now', '-5 days') * 1000),

('t1111111-1111-1111-1111-111111111114', 'PURCHASE', 'p1111111-1111-1111-1111-111111111112', 12, NULL, 'Compra inicial de inventario', 'u1111111-1111-1111-1111-111111111112', 'a1111111-1111-1111-1111-111111111111', NULL, NULL, strftime('%s', 'now', '-5 days') * 1000, strftime('%s', 'now', '-5 days') * 1000, strftime('%s', 'now', '-5 days') * 1000, 'SYNCED', strftime('%s', 'now', '-5 days') * 1000),

('t1111111-1111-1111-1111-111111111115', 'PURCHASE', 'p1111111-1111-1111-1111-111111111115', 15, NULL, 'Compra inicial de inventario', 'u1111111-1111-1111-1111-111111111112', 'a1111111-1111-1111-1111-111111111111', NULL, NULL, strftime('%s', 'now', '-5 days') * 1000, strftime('%s', 'now', '-5 days') * 1000, strftime('%s', 'now', '-5 days') * 1000, 'SYNCED', strftime('%s', 'now', '-5 days') * 1000);

-- Ventas recientes (sincronizadas)
INSERT INTO transactions (id, type, product_id, quantity, price, reason, user_id, sede_id, transfer_id, metadata, client_timestamp, server_timestamp, synced_at, sync_status, created_at) VALUES
('t1111111-1111-1111-1111-111111111116', 'SALE', 'p1111111-1111-1111-1111-111111111111', -3, 2500000.00, 'Venta a cliente', 'u1111111-1111-1111-1111-111111111113', 'a1111111-1111-1111-1111-111111111111', NULL, '{"payment_method": "credit_card", "customer": "Cliente A"}', strftime('%s', 'now', '-3 days') * 1000, strftime('%s', 'now', '-3 days') * 1000, strftime('%s', 'now', '-3 days') * 1000, 'SYNCED', strftime('%s', 'now', '-3 days') * 1000),

('t1111111-1111-1111-1111-111111111117', 'SALE', 'p1111111-1111-1111-1111-111111111113', -5, 350000.00, 'Venta a cliente', 'u1111111-1111-1111-1111-111111111113', 'a1111111-1111-1111-1111-111111111111', NULL, '{"payment_method": "cash", "customer": "Cliente B"}', strftime('%s', 'now', '-2 days') * 1000, strftime('%s', 'now', '-2 days') * 1000, strftime('%s', 'now', '-2 days') * 1000, 'SYNCED', strftime('%s', 'now', '-2 days') * 1000),

('t1111111-1111-1111-1111-111111111118', 'SALE', 'p1111111-1111-1111-1111-111111111112', -2, 3200000.00, 'Venta a cliente', 'u1111111-1111-1111-1111-111111111113', 'a1111111-1111-1111-1111-111111111111', NULL, '{"payment_method": "credit_card", "customer": "Cliente C"}', strftime('%s', 'now', '-1 day') * 1000, strftime('%s', 'now', '-1 day') * 1000, strftime('%s', 'now', '-1 day') * 1000, 'SYNCED', strftime('%s', 'now', '-1 day') * 1000);

-- Ajuste de inventario (sincronizado)
INSERT INTO transactions (id, type, product_id, quantity, price, reason, user_id, sede_id, transfer_id, metadata, client_timestamp, server_timestamp, synced_at, sync_status, created_at) VALUES
('t1111111-1111-1111-1111-111111111119', 'ADJUSTMENT', 'p1111111-1111-1111-1111-111111111112', -2, NULL, 'Ajuste por inventario físico - productos dañados', 'u1111111-1111-1111-1111-111111111112', 'a1111111-1111-1111-1111-111111111111', NULL, NULL, strftime('%s', 'now', '-12 hours') * 1000, strftime('%s', 'now', '-12 hours') * 1000, strftime('%s', 'now', '-12 hours') * 1000, 'SYNCED', strftime('%s', 'now', '-12 hours') * 1000);

-- Ventas pendientes de sincronizar (offline)
INSERT INTO transactions (id, type, product_id, quantity, price, reason, user_id, sede_id, transfer_id, metadata, client_timestamp, server_timestamp, synced_at, sync_status, created_at) VALUES
('t1111111-1111-1111-1111-999999999991', 'SALE', 'p1111111-1111-1111-1111-111111111114', -3, 450000.00, 'Venta a cliente', 'u1111111-1111-1111-1111-111111111113', 'a1111111-1111-1111-1111-111111111111', NULL, '{"payment_method": "cash", "customer": "Cliente D"}', strftime('%s', 'now', '-30 minutes') * 1000, NULL, NULL, 'PENDING', strftime('%s', 'now', '-30 minutes') * 1000),

('t1111111-1111-1111-1111-999999999992', 'SALE', 'p1111111-1111-1111-1111-111111111113', -2, 350000.00, 'Venta a cliente', 'u1111111-1111-1111-1111-111111111113', 'a1111111-1111-1111-1111-111111111111', NULL, '{"payment_method": "debit_card", "customer": "Cliente E"}', strftime('%s', 'now', '-15 minutes') * 1000, NULL, NULL, 'PENDING', strftime('%s', 'now', '-15 minutes') * 1000);

-- =====================================================
-- VERIFICACIÓN DE DATOS
-- =====================================================

SELECT '=== RESUMEN DE DATOS INSERTADOS ===' AS info;
SELECT 'Usuarios: ' || COUNT(*) AS info FROM users;
SELECT 'Productos: ' || COUNT(*) AS info FROM products;
SELECT 'Registros de Inventario: ' || COUNT(*) AS info FROM inventory;
SELECT 'Transacciones: ' || COUNT(*) AS info FROM transactions;
SELECT 'Transacciones Pendientes: ' || COUNT(*) AS info FROM transactions WHERE sync_status = 'PENDING';
SELECT 'Items en Sync Queue: ' || COUNT(*) AS info FROM sync_queue;
SELECT '====================================' AS info;

-- Mostrar stock actual
SELECT 
    p.sku,
    p.name,
    i.quantity AS stock,
    i.min_stock,
    CASE 
        WHEN i.quantity < i.min_stock THEN 'BAJO'
        WHEN i.quantity = 0 THEN 'AGOTADO'
        ELSE 'OK'
    END AS status
FROM products p
JOIN inventory i ON p.id = i.product_id
WHERE p.deleted = 0
ORDER BY p.category, p.name;

-- =====================================================
-- FIN DEL SCRIPT DE SEED DATA
-- =====================================================
