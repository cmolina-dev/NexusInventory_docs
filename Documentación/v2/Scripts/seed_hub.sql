-- =====================================================
-- Stocky v2 - Script de Datos de Prueba (Seed Data Hub)
-- Versión: 2.0
-- Creado: 2026-02-09
-- Descripción: Datos de prueba para desarrollo y testing
-- =====================================================

-- IMPORTANTE: Este script asume que ya se ejecutó hub.sql
-- y que la extensión uuid-ossp está habilitada

-- =====================================================
-- LIMPIAR DATOS EXISTENTES (OPCIONAL - COMENTADO)
-- =====================================================
-- ADVERTENCIA: Esto eliminará TODOS los datos
-- Descomenta solo si quieres empezar desde cero

/*
TRUNCATE TABLE sync_logs CASCADE;
TRUNCATE TABLE audit_logs CASCADE;
TRUNCATE TABLE transfers CASCADE;
TRUNCATE TABLE transactions CASCADE;
TRUNCATE TABLE inventory CASCADE;
TRUNCATE TABLE products CASCADE;
TRUNCATE TABLE users CASCADE;
TRUNCATE TABLE activation_codes CASCADE;
TRUNCATE TABLE sedes CASCADE;
TRUNCATE TABLE tenants CASCADE;
*/

-- =====================================================
-- 1. TENANTS (Organizaciones)
-- =====================================================

INSERT INTO tenants (id, name, email, plan, status, settings, created_at) VALUES
-- Tenant 1: TechStore (Plan Premium)
('11111111-1111-1111-1111-111111111111', 'TechStore Colombia', 'admin@techstore.com', 'PREMIUM', 'ACTIVE', 
 '{"logo": "https://example.com/techstore-logo.png", "theme": "blue", "currency": "COP", "timezone": "America/Bogota"}'::jsonb,
 NOW() - INTERVAL '6 months'),

-- Tenant 2: FashionHub (Plan Basic)
('22222222-2222-2222-2222-222222222222', 'FashionHub', 'admin@fashionhub.com', 'BASIC', 'ACTIVE',
 '{"logo": "https://example.com/fashionhub-logo.png", "theme": "pink", "currency": "COP", "timezone": "America/Bogota"}'::jsonb,
 NOW() - INTERVAL '3 months'),

-- Tenant 3: MercadoLocal (Plan Free)
('33333333-3333-3333-3333-333333333333', 'MercadoLocal', 'admin@mercadolocal.com', 'FREE', 'ACTIVE',
 '{"currency": "COP", "timezone": "America/Bogota"}'::jsonb,
 NOW() - INTERVAL '1 month');

-- =====================================================
-- 2. SEDES (Sucursales)
-- =====================================================

-- Sedes de TechStore
INSERT INTO sedes (id, tenant_id, name, code, address, status, is_online, last_sync_at, last_ping_at, sync_version, created_at) VALUES
('a1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 
 'TechStore Centro', 'TS-CEN', 'Carrera 7 #32-16, Bogotá', 'ACTIVE', TRUE, NOW() - INTERVAL '5 minutes', NOW() - INTERVAL '30 seconds', 125, NOW() - INTERVAL '6 months'),
 
('a1111111-1111-1111-1111-111111111112', '11111111-1111-1111-1111-111111111111',
 'TechStore Norte', 'TS-NOR', 'Calle 170 #45-23, Bogotá', 'ACTIVE', TRUE, NOW() - INTERVAL '10 minutes', NOW() - INTERVAL '45 seconds', 98, NOW() - INTERVAL '5 months'),
 
('a1111111-1111-1111-1111-111111111113', '11111111-1111-1111-1111-111111111111',
 'TechStore Sur', 'TS-SUR', 'Autopista Sur #78-45, Bogotá', 'ACTIVE', FALSE, NOW() - INTERVAL '3 hours', NOW() - INTERVAL '3 hours', 87, NOW() - INTERVAL '4 months'),

-- Sedes de FashionHub
('a2222222-2222-2222-2222-222222222221', '22222222-2222-2222-2222-222222222222',
 'FashionHub Unicentro', 'FH-UNI', 'Centro Comercial Unicentro, Bogotá', 'ACTIVE', TRUE, NOW() - INTERVAL '8 minutes', NOW() - INTERVAL '1 minute', 156, NOW() - INTERVAL '3 months'),
 
('a2222222-2222-2222-2222-222222222222', '22222222-2222-2222-2222-222222222222',
 'FashionHub Andino', 'FH-AND', 'Centro Andino, Bogotá', 'ACTIVE', TRUE, NOW() - INTERVAL '20 minutes', NOW() - INTERVAL '2 minutes', 142, NOW() - INTERVAL '2 months'),

-- Sede de MercadoLocal
('a3333333-3333-3333-3333-333333333331', '33333333-3333-3333-3333-333333333333',
 'MercadoLocal Principal', 'ML-PRI', 'Calle 45 #12-34, Medellín', 'ACTIVE', TRUE, NOW() - INTERVAL '30 minutes', NOW() - INTERVAL '1 minute', 45, NOW() - INTERVAL '1 month');

-- =====================================================
-- 3. ACTIVATION_CODES (Códigos de Activación)
-- =====================================================

INSERT INTO activation_codes (id, sede_id, code, is_used, used_at, client_info, expires_at, created_at) VALUES
-- Códigos usados
('ac111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'ABC123', TRUE, NOW() - INTERVAL '6 months',
 '{"device": "Windows 11 Pro", "app_version": "2.0.0", "hostname": "TECHSTORE-POS-01"}'::jsonb, NOW() + INTERVAL '7 days', NOW() - INTERVAL '6 months'),

('ac111111-1111-1111-1111-111111111112', 'a1111111-1111-1111-1111-111111111112', 'DEF456', TRUE, NOW() - INTERVAL '5 months',
 '{"device": "Windows 10 Pro", "app_version": "2.0.0", "hostname": "TECHSTORE-POS-02"}'::jsonb, NOW() + INTERVAL '7 days', NOW() - INTERVAL '5 months'),

-- Código pendiente de uso
('ac111111-1111-1111-1111-111111111113', 'a1111111-1111-1111-1111-111111111113', 'GHI789', FALSE, NULL, NULL, NOW() + INTERVAL '7 days', NOW() - INTERVAL '1 day'),

-- Código expirado no usado
('ac222222-2222-2222-2222-222222222221', 'a2222222-2222-2222-2222-222222222221', 'JKL012', FALSE, NULL, NULL, NOW() - INTERVAL '1 day', NOW() - INTERVAL '8 days');

-- =====================================================
-- 4. USERS (Usuarios)
-- =====================================================

-- Usuarios de TechStore
INSERT INTO users (id, tenant_id, sede_id, email, password_hash, name, role, status, last_login_at, created_at) VALUES
-- Admin de TechStore (puede ver todas las sedes)
('u1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', NULL,
 'admin@techstore.com', '$2b$10$abcdefghijklmnopqrstuvwxyz123456', 'Carlos Administrador', 'TENANT_ADMIN', 'ACTIVE', NOW() - INTERVAL '1 hour', NOW() - INTERVAL '6 months'),

-- Manager TechStore Centro
('u1111111-1111-1111-1111-111111111112', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111',
 'manager.centro@techstore.com', '$2b$10$abcdefghijklmnopqrstuvwxyz123456', 'María Gerente Centro', 'MANAGER', 'ACTIVE', NOW() - INTERVAL '2 hours', NOW() - INTERVAL '6 months'),

-- Staff TechStore Centro
('u1111111-1111-1111-1111-111111111113', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111',
 'vendedor1.centro@techstore.com', '$2b$10$abcdefghijklmnopqrstuvwxyz123456', 'Juan Vendedor', 'STAFF', 'ACTIVE', NOW() - INTERVAL '30 minutes', NOW() - INTERVAL '5 months'),

-- Manager TechStore Norte
('u1111111-1111-1111-1111-111111111114', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111112',
 'manager.norte@techstore.com', '$2b$10$abcdefghijklmnopqrstuvwxyz123456', 'Pedro Gerente Norte', 'MANAGER', 'ACTIVE', NOW() - INTERVAL '3 hours', NOW() - INTERVAL '5 months'),

-- Staff TechStore Sur
('u1111111-1111-1111-1111-111111111115', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111113',
 'vendedor1.sur@techstore.com', '$2b$10$abcdefghijklmnopqrstuvwxyz123456', 'Ana Vendedora Sur', 'STAFF', 'ACTIVE', NOW() - INTERVAL '1 hour', NOW() - INTERVAL '4 months'),

-- Usuarios de FashionHub
('u2222222-2222-2222-2222-222222222221', '22222222-2222-2222-2222-222222222222', NULL,
 'admin@fashionhub.com', '$2b$10$abcdefghijklmnopqrstuvwxyz123456', 'Laura Admin', 'TENANT_ADMIN', 'ACTIVE', NOW() - INTERVAL '4 hours', NOW() - INTERVAL '3 months'),

('u2222222-2222-2222-2222-222222222222', '22222222-2222-2222-2222-222222222222', 'a2222222-2222-2222-2222-222222222221',
 'manager.unicentro@fashionhub.com', '$2b$10$abcdefghijklmnopqrstuvwxyz123456', 'Sofia Manager', 'MANAGER', 'ACTIVE', NOW() - INTERVAL '2 hours', NOW() - INTERVAL '3 months'),

-- Usuario de MercadoLocal
('u3333333-3333-3333-3333-333333333331', '33333333-3333-3333-3333-333333333333', 'a3333333-3333-3333-3333-333333333331',
 'admin@mercadolocal.com', '$2b$10$abcdefghijklmnopqrstuvwxyz123456', 'Roberto Dueño', 'TENANT_ADMIN', 'ACTIVE', NOW() - INTERVAL '5 hours', NOW() - INTERVAL '1 month');

-- =====================================================
-- 5. PRODUCTS (Catálogo de Productos)
-- =====================================================

-- Productos de TechStore (Tecnología)
INSERT INTO products (id, tenant_id, sku, barcode, name, description, category, price, cost, unit, metadata, version, last_modified_by, last_modified_at, created_at) VALUES
('p1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111',
 'LAP-HP-001', '7501234567890', 'Laptop HP Pavilion 15', 'Laptop HP Pavilion 15.6", Intel i5, 8GB RAM, 256GB SSD', 'Laptops', 2500000.00, 1800000.00, 'UNIT',
 '{"brand": "HP", "warranty": "12 months", "images": ["laptop-hp-001.jpg"], "supplier": "HP Colombia"}'::jsonb, 3, 'u1111111-1111-1111-1111-111111111111', NOW() - INTERVAL '2 days', NOW() - INTERVAL '6 months'),

('p1111111-1111-1111-1111-111111111112', '11111111-1111-1111-1111-111111111111',
 'LAP-DEL-001', '7501234567891', 'Laptop Dell Inspiron 14', 'Laptop Dell Inspiron 14", Intel i7, 16GB RAM, 512GB SSD', 'Laptops', 3200000.00, 2400000.00, 'UNIT',
 '{"brand": "Dell", "warranty": "12 months", "images": ["laptop-dell-001.jpg"], "supplier": "Dell Colombia"}'::jsonb, 1, 'u1111111-1111-1111-1111-111111111111', NOW() - INTERVAL '6 months', NOW() - INTERVAL '6 months'),

('p1111111-1111-1111-1111-111111111113', '11111111-1111-1111-1111-111111111111',
 'MOU-LOG-001', '7501234567892', 'Mouse Logitech MX Master 3', 'Mouse inalámbrico ergonómico Logitech MX Master 3', 'Accesorios', 350000.00, 220000.00, 'UNIT',
 '{"brand": "Logitech", "warranty": "24 months", "wireless": true}'::jsonb, 1, NULL, NOW() - INTERVAL '5 months', NOW() - INTERVAL '5 months'),

('p1111111-1111-1111-1111-111111111114', '11111111-1111-1111-1111-111111111111',
 'KEY-COR-001', '7501234567893', 'Teclado Corsair K70', 'Teclado mecánico RGB Corsair K70', 'Accesorios', 450000.00, 300000.00, 'UNIT',
 '{"brand": "Corsair", "warranty": "24 months", "mechanical": true, "rgb": true}'::jsonb, 2, 'u1111111-1111-1111-1111-111111111112', NOW() - INTERVAL '1 month', NOW() - INTERVAL '5 months'),

('p1111111-1111-1111-1111-111111111115', '11111111-1111-1111-1111-111111111111',
 'MON-SAM-001', '7501234567894', 'Monitor Samsung 27" 4K', 'Monitor Samsung 27 pulgadas, resolución 4K UHD', 'Monitores', 1200000.00, 850000.00, 'UNIT',
 '{"brand": "Samsung", "warranty": "36 months", "resolution": "3840x2160"}'::jsonb, 1, NULL, NOW() - INTERVAL '4 months', NOW() - INTERVAL '4 months'),

-- Productos de FashionHub (Ropa)
('p2222222-2222-2222-2222-222222222221', '22222222-2222-2222-2222-222222222222',
 'CAM-HOM-001', '7502345678901', 'Camisa Hombre Formal Blanca', 'Camisa formal para hombre, color blanco, talla M', 'Ropa Hombre', 89000.00, 45000.00, 'UNIT',
 '{"sizes": ["S", "M", "L", "XL"], "color": "white", "material": "cotton"}'::jsonb, 1, NULL, NOW() - INTERVAL '3 months', NOW() - INTERVAL '3 months'),

('p2222222-2222-2222-2222-222222222222', '22222222-2222-2222-2222-222222222222',
 'PAN-MUJ-001', '7502345678902', 'Pantalón Jean Mujer', 'Pantalón jean para mujer, corte skinny', 'Ropa Mujer', 120000.00, 60000.00, 'UNIT',
 '{"sizes": ["XS", "S", "M", "L"], "color": "blue", "material": "denim"}'::jsonb, 1, NULL, NOW() - INTERVAL '3 months', NOW() - INTERVAL '3 months'),

('p2222222-2222-2222-2222-222222222223', '22222222-2222-2222-2222-222222222222',
 'ZAP-DEP-001', '7502345678903', 'Zapatos Deportivos Nike', 'Zapatos deportivos Nike Air Max', 'Calzado', 280000.00, 180000.00, 'UNIT',
 '{"brand": "Nike", "sizes": ["38", "39", "40", "41", "42"], "color": "black"}'::jsonb, 1, NULL, NOW() - INTERVAL '2 months', NOW() - INTERVAL '2 months'),

-- Productos de MercadoLocal (Abarrotes)
('p3333333-3333-3333-3333-333333333331', '33333333-3333-3333-3333-333333333333',
 'ARR-DIA-001', '7503456789012', 'Arroz Diana x 500g', 'Arroz blanco Diana, empaque de 500 gramos', 'Abarrotes', 2500.00, 1800.00, 'UNIT',
 '{"brand": "Diana", "weight": "500g"}'::jsonb, 1, NULL, NOW() - INTERVAL '1 month', NOW() - INTERVAL '1 month'),

('p3333333-3333-3333-3333-333333333332', '33333333-3333-3333-3333-333333333333',
 'ACE-OLI-001', '7503456789013', 'Aceite Oliva x 1L', 'Aceite de oliva extra virgen, botella de 1 litro', 'Abarrotes', 35000.00, 22000.00, 'LITER',
 '{"brand": "Carbonell", "volume": "1L"}'::jsonb, 1, NULL, NOW() - INTERVAL '1 month', NOW() - INTERVAL '1 month');

-- =====================================================
-- 6. INVENTORY (Stock por Sede)
-- =====================================================

-- Inventario TechStore Centro
INSERT INTO inventory (id, tenant_id, sede_id, product_id, quantity, min_stock, max_stock, version, last_updated_at) VALUES
('i1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'p1111111-1111-1111-1111-111111111111', 15, 5, 30, 5, NOW() - INTERVAL '5 minutes'),
('i1111111-1111-1111-1111-111111111112', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'p1111111-1111-1111-1111-111111111112', 8, 3, 20, 3, NOW() - INTERVAL '5 minutes'),
('i1111111-1111-1111-1111-111111111113', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'p1111111-1111-1111-1111-111111111113', 45, 10, 100, 8, NOW() - INTERVAL '5 minutes'),
('i1111111-1111-1111-1111-111111111114', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'p1111111-1111-1111-1111-111111111114', 32, 10, 80, 4, NOW() - INTERVAL '5 minutes'),
('i1111111-1111-1111-1111-111111111115', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'p1111111-1111-1111-1111-111111111115', 12, 5, 25, 2, NOW() - INTERVAL '5 minutes'),

-- Inventario TechStore Norte
('i1111111-1111-1111-1111-222222222221', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111112', 'p1111111-1111-1111-1111-111111111111', 22, 5, 30, 7, NOW() - INTERVAL '10 minutes'),
('i1111111-1111-1111-1111-222222222222', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111112', 'p1111111-1111-1111-1111-111111111112', 12, 3, 20, 2, NOW() - INTERVAL '10 minutes'),
('i1111111-1111-1111-1111-222222222223', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111112', 'p1111111-1111-1111-1111-111111111113', 67, 10, 100, 5, NOW() - INTERVAL '10 minutes'),
('i1111111-1111-1111-1111-222222222224', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111112', 'p1111111-1111-1111-1111-111111111115', 8, 5, 25, 1, NOW() - INTERVAL '10 minutes'),

-- Inventario TechStore Sur (con stock bajo)
('i1111111-1111-1111-1111-333333333331', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111113', 'p1111111-1111-1111-1111-111111111111', 3, 5, 30, 12, NOW() - INTERVAL '3 hours'),
('i1111111-1111-1111-1111-333333333332', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111113', 'p1111111-1111-1111-1111-111111111113', 28, 10, 100, 6, NOW() - INTERVAL '3 hours'),
('i1111111-1111-1111-1111-333333333333', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111113', 'p1111111-1111-1111-1111-111111111114', 55, 10, 80, 3, NOW() - INTERVAL '3 hours'),

-- Inventario FashionHub
('i2222222-2222-2222-2222-111111111111', '22222222-2222-2222-2222-222222222222', 'a2222222-2222-2222-2222-222222222221', 'p2222222-2222-2222-2222-222222222221', 120, 20, 200, 15, NOW() - INTERVAL '8 minutes'),
('i2222222-2222-2222-2222-111111111112', '22222222-2222-2222-2222-222222222222', 'a2222222-2222-2222-2222-222222222221', 'p2222222-2222-2222-2222-222222222222', 85, 15, 150, 12, NOW() - INTERVAL '8 minutes'),
('i2222222-2222-2222-2222-111111111113', '22222222-2222-2222-2222-222222222222', 'a2222222-2222-2222-2222-222222222221', 'p2222222-2222-2222-2222-222222222223', 45, 10, 80, 8, NOW() - INTERVAL '8 minutes'),

-- Inventario MercadoLocal
('i3333333-3333-3333-3333-111111111111', '33333333-3333-3333-3333-333333333333', 'a3333333-3333-3333-3333-333333333331', 'p3333333-3333-3333-3333-333333333331', 450, 100, 1000, 22, NOW() - INTERVAL '30 minutes'),
('i3333333-3333-3333-3333-111111111112', '33333333-3333-3333-3333-333333333333', 'a3333333-3333-3333-3333-333333333331', 'p3333333-3333-3333-3333-333333333332', 78, 20, 150, 10, NOW() - INTERVAL '30 minutes');

-- =====================================================
-- 7. TRANSACTIONS (Historial de Transacciones)
-- =====================================================

-- Transacciones TechStore Centro
INSERT INTO transactions (id, tenant_id, sede_id, product_id, user_id, type, quantity, price, reason, client_timestamp, server_timestamp, synced_at) VALUES
-- Entradas de inventario
('t1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'p1111111-1111-1111-1111-111111111111', 'u1111111-1111-1111-1111-111111111112', 'PURCHASE', 20, NULL, 'Compra inicial de inventario', NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),
('t1111111-1111-1111-1111-111111111112', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'p1111111-1111-1111-1111-111111111113', 'u1111111-1111-1111-1111-111111111112', 'PURCHASE', 50, NULL, 'Compra inicial de inventario', NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),

-- Ventas
('t1111111-1111-1111-1111-111111111113', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'p1111111-1111-1111-1111-111111111111', 'u1111111-1111-1111-1111-111111111113', 'SALE', -3, 2500000.00, 'Venta a cliente', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
('t1111111-1111-1111-1111-111111111114', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'p1111111-1111-1111-1111-111111111113', 'u1111111-1111-1111-1111-111111111113', 'SALE', -5, 350000.00, 'Venta a cliente', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
('t1111111-1111-1111-1111-111111111115', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'p1111111-1111-1111-1111-111111111112', 'u1111111-1111-1111-1111-111111111113', 'SALE', -2, 3200000.00, 'Venta a cliente', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),

-- Ajuste
('t1111111-1111-1111-1111-111111111116', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'p1111111-1111-1111-1111-111111111112', 'u1111111-1111-1111-1111-111111111112', 'ADJUSTMENT', -2, NULL, 'Ajuste por inventario físico - productos dañados', NOW() - INTERVAL '12 hours', NOW() - INTERVAL '12 hours', NOW() - INTERVAL '12 hours');

-- =====================================================
-- 8. TRANSFERS (Transferencias entre Sedes)
-- =====================================================

-- Transferencia completada
INSERT INTO transfers (id, tenant_id, from_sede_id, to_sede_id, product_id, requested_by, approved_by, quantity, status, requested_at, approved_at, completed_at) VALUES
('tf111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 
 'a1111111-1111-1111-1111-111111111112', 'a1111111-1111-1111-1111-111111111113', 
 'p1111111-1111-1111-1111-111111111111', 
 'u1111111-1111-1111-1111-111111111115', 'u1111111-1111-1111-1111-111111111114', 
 5, 'COMPLETED', 
 NOW() - INTERVAL '2 days', 
 NOW() - INTERVAL '2 days' + INTERVAL '30 minutes',
 NOW() - INTERVAL '2 days' + INTERVAL '1 hour'),

-- Transferencia pendiente
('tf111111-1111-1111-1111-111111111112', '11111111-1111-1111-1111-111111111111',
 'a1111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111113', 
 'p1111111-1111-1111-1111-111111111114', 
 'u1111111-1111-1111-1111-111111111115', NULL, 
 10, 'PENDING',
 NOW() - INTERVAL '3 hours', NULL, NULL);

-- Transacciones de la transferencia completada
INSERT INTO transactions (id, tenant_id, sede_id, product_id, user_id, type, quantity, reason, transfer_id, client_timestamp, server_timestamp, synced_at) VALUES
('t1111111-1111-1111-1111-999999999991', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111112', 'p1111111-1111-1111-1111-111111111111', 'u1111111-1111-1111-1111-111111111114', 'TRANSFER_OUT', -5, 'Transferencia a TechStore Sur', 'tf111111-1111-1111-1111-111111111111', NOW() - INTERVAL '2 days' + INTERVAL '1 hour', NOW() - INTERVAL '2 days' + INTERVAL '1 hour', NOW() - INTERVAL '2 days' + INTERVAL '1 hour'),
('t1111111-1111-1111-1111-999999999992', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111113', 'p1111111-1111-1111-1111-111111111111', 'u1111111-1111-1111-1111-111111111115', 'TRANSFER_IN', 5, 'Recepción desde TechStore Norte', 'tf111111-1111-1111-1111-111111111111', NOW() - INTERVAL '2 days' + INTERVAL '1 hour', NOW() - INTERVAL '2 days' + INTERVAL '1 hour', NOW() - INTERVAL '2 days' + INTERVAL '1 hour');

-- =====================================================
-- 9. AUDIT_LOGS (Registros de Auditoría)
-- =====================================================

INSERT INTO audit_logs (id, tenant_id, user_id, sede_id, action, entity_type, entity_id, before_data, after_data, ip_address, user_agent, timestamp) VALUES
('al111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'u1111111-1111-1111-1111-111111111111', NULL, 'CREATE', 'PRODUCT', 'p1111111-1111-1111-1111-111111111111', NULL, '{"product_name": "Laptop HP Pavilion 15", "sku": "LAP-HP-001"}'::jsonb, '192.168.1.100', 'Tauri/2.0.0 (Windows)', NOW() - INTERVAL '6 months'),

('al111111-1111-1111-1111-111111111112', '11111111-1111-1111-1111-111111111111', 'u1111111-1111-1111-1111-111111111114', 'a1111111-1111-1111-1111-111111111112', 'UPDATE', 'TRANSFER', 'tf111111-1111-1111-1111-111111111111', '{"status": "PENDING"}'::jsonb, '{"status": "APPROVED"}'::jsonb, '192.168.1.105', 'Tauri/2.0.0 (Windows)', NOW() - INTERVAL '2 days' + INTERVAL '30 minutes'),

('al111111-1111-1111-1111-111111111113', '11111111-1111-1111-1111-111111111111', 'u1111111-1111-1111-1111-111111111113', 'a1111111-1111-1111-1111-111111111111', 'SYNC', 'TRANSACTION', NULL, NULL, '{"action": "push", "records": 5}'::jsonb, '192.168.1.102', 'Tauri/2.0.0 (Windows)', NOW() - INTERVAL '5 minutes');

-- =====================================================
-- 10. SYNC_LOGS (Logs de Sincronización)
-- =====================================================

INSERT INTO sync_logs (id, tenant_id, sede_id, direction, entity_type, records_count, success, conflicts_detected, conflicts_resolved, duration_ms, timestamp) VALUES
('sl111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'PUSH', 'transactions', 15, TRUE, 0, 0, 1250, NOW() - INTERVAL '5 minutes'),
('sl111111-1111-1111-1111-111111111112', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'PULL', 'products', 5, TRUE, 1, 1, 850, NOW() - INTERVAL '5 minutes'),
('sl111111-1111-1111-1111-111111111113', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111112', 'PUSH', 'transactions', 8, TRUE, 0, 0, 980, NOW() - INTERVAL '10 minutes'),
('sl222222-2222-2222-2222-111111111111', '22222222-2222-2222-2222-222222222222', 'a2222222-2222-2222-2222-222222222221', 'PUSH', 'transactions', 25, TRUE, 0, 0, 1850, NOW() - INTERVAL '8 minutes');

-- =====================================================
-- VERIFICACIÓN DE DATOS
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '=== RESUMEN DE DATOS INSERTADOS ===';
    RAISE NOTICE 'Tenants: %', (SELECT COUNT(*) FROM tenants);
    RAISE NOTICE 'Sedes: %', (SELECT COUNT(*) FROM sedes);
    RAISE NOTICE 'Activation Codes: %', (SELECT COUNT(*) FROM activation_codes);
    RAISE NOTICE 'Usuarios: %', (SELECT COUNT(*) FROM users);
    RAISE NOTICE 'Productos: %', (SELECT COUNT(*) FROM products);
    RAISE NOTICE 'Registros de Inventario: %', (SELECT COUNT(*) FROM inventory);
    RAISE NOTICE 'Transacciones: %', (SELECT COUNT(*) FROM transactions);
    RAISE NOTICE 'Transferencias: %', (SELECT COUNT(*) FROM transfers);
    RAISE NOTICE 'Logs de Auditoría: %', (SELECT COUNT(*) FROM audit_logs);
    RAISE NOTICE 'Logs de Sincronización: %', (SELECT COUNT(*) FROM sync_logs);
    RAISE NOTICE '====================================';
END $$;

-- =====================================================
-- FIN DEL SCRIPT DE SEED DATA
-- =====================================================
