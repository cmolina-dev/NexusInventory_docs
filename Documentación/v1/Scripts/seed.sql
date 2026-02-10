-- =====================================================
-- Stocky - Script de Datos de Prueba (Seed Data)
-- Versión: 1.0
-- Creado: 2026-02-07
-- Descripción: Datos de prueba para desarrollo y testing
-- =====================================================

-- IMPORTANTE: Este script asume que ya se ejecutó schema_hub.sql
-- y que la extensión uuid-ossp está habilitada

-- =====================================================
-- LIMPIAR DATOS EXISTENTES (OPCIONAL - COMENTADO)
-- =====================================================
-- ADVERTENCIA: Esto eliminará TODOS los datos
-- Descomenta solo si quieres empezar desde cero

/*
TRUNCATE TABLE audit_logs CASCADE;
TRUNCATE TABLE transfers CASCADE;
TRUNCATE TABLE transactions_log CASCADE;
TRUNCATE TABLE inventory_consolidated CASCADE;
TRUNCATE TABLE products_consolidated CASCADE;
TRUNCATE TABLE users CASCADE;
TRUNCATE TABLE sedes CASCADE;
TRUNCATE TABLE tenants CASCADE;
*/

-- =====================================================
-- 1. TENANTS (Organizaciones)
-- =====================================================

INSERT INTO tenants (id, name, plan, status, settings, created_at) VALUES
-- Tenant 1: TechStore (Plan Premium)
('11111111-1111-1111-1111-111111111111', 'TechStore Colombia', 'PREMIUM', 'ACTIVE', 
 '{"logo": "https://example.com/techstore-logo.png", "theme": "blue", "currency": "COP", "timezone": "America/Bogota"}'::jsonb,
 NOW() - INTERVAL '6 months'),

-- Tenant 2: FashionHub (Plan Basic)
('22222222-2222-2222-2222-222222222222', 'FashionHub', 'BASIC', 'ACTIVE',
 '{"logo": "https://example.com/fashionhub-logo.png", "theme": "pink", "currency": "COP", "timezone": "America/Bogota"}'::jsonb,
 NOW() - INTERVAL '3 months'),

-- Tenant 3: MercadoLocal (Plan Free)
('33333333-3333-3333-3333-333333333333', 'MercadoLocal', 'FREE', 'ACTIVE',
 '{"currency": "COP", "timezone": "America/Bogota"}'::jsonb,
 NOW() - INTERVAL '1 month');

-- =====================================================
-- 2. SEDES (Sucursales)
-- =====================================================

-- Sedes de TechStore
INSERT INTO sedes (id, tenant_id, name, code, address, status, last_sync_at, created_at) VALUES
('a1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 
 'TechStore Centro', 'TS-CEN', 'Carrera 7 #32-16, Bogotá', 'ACTIVE', NOW() - INTERVAL '5 minutes', NOW() - INTERVAL '6 months'),
 
('a1111111-1111-1111-1111-111111111112', '11111111-1111-1111-1111-111111111111',
 'TechStore Norte', 'TS-NOR', 'Calle 170 #45-23, Bogotá', 'ACTIVE', NOW() - INTERVAL '10 minutes', NOW() - INTERVAL '5 months'),
 
('a1111111-1111-1111-1111-111111111113', '11111111-1111-1111-1111-111111111111',
 'TechStore Sur', 'TS-SUR', 'Autopista Sur #78-45, Bogotá', 'ACTIVE', NOW() - INTERVAL '15 minutes', NOW() - INTERVAL '4 months'),

-- Sedes de FashionHub
('a2222222-2222-2222-2222-222222222221', '22222222-2222-2222-2222-222222222222',
 'FashionHub Unicentro', 'FH-UNI', 'Centro Comercial Unicentro, Bogotá', 'ACTIVE', NOW() - INTERVAL '8 minutes', NOW() - INTERVAL '3 months'),
 
('a2222222-2222-2222-2222-222222222222', '22222222-2222-2222-2222-222222222222',
 'FashionHub Andino', 'FH-AND', 'Centro Andino, Bogotá', 'ACTIVE', NOW() - INTERVAL '20 minutes', NOW() - INTERVAL '2 months'),

-- Sede de MercadoLocal
('a3333333-3333-3333-3333-333333333331', '33333333-3333-3333-3333-333333333333',
 'MercadoLocal Principal', 'ML-PRI', 'Calle 45 #12-34, Medellín', 'ACTIVE', NOW() - INTERVAL '30 minutes', NOW() - INTERVAL '1 month');

-- =====================================================
-- 3. USERS (Usuarios)
-- =====================================================

-- Usuarios de TechStore
INSERT INTO users (id, tenant_id, sede_id, email, password_hash, role, status, last_login_at, created_at) VALUES
-- Admin de TechStore (puede ver todas las sedes)
('u1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', NULL,
 'admin@techstore.com', '$2b$10$abcdefghijklmnopqrstuvwxyz123456', 'TENANT_ADMIN', 'ACTIVE', NOW() - INTERVAL '1 hour', NOW() - INTERVAL '6 months'),

-- Manager TechStore Centro
('u1111111-1111-1111-1111-111111111112', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111',
 'manager.centro@techstore.com', '$2b$10$abcdefghijklmnopqrstuvwxyz123456', 'MANAGER', 'ACTIVE', NOW() - INTERVAL '2 hours', NOW() - INTERVAL '6 months'),

-- Staff TechStore Centro
('u1111111-1111-1111-1111-111111111113', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111',
 'vendedor1.centro@techstore.com', '$2b$10$abcdefghijklmnopqrstuvwxyz123456', 'STAFF', 'ACTIVE', NOW() - INTERVAL '30 minutes', NOW() - INTERVAL '5 months'),

-- Manager TechStore Norte
('u1111111-1111-1111-1111-111111111114', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111112',
 'manager.norte@techstore.com', '$2b$10$abcdefghijklmnopqrstuvwxyz123456', 'MANAGER', 'ACTIVE', NOW() - INTERVAL '3 hours', NOW() - INTERVAL '5 months'),

-- Staff TechStore Sur
('u1111111-1111-1111-1111-111111111115', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111113',
 'vendedor1.sur@techstore.com', '$2b$10$abcdefghijklmnopqrstuvwxyz123456', 'STAFF', 'ACTIVE', NOW() - INTERVAL '1 hour', NOW() - INTERVAL '4 months'),

-- Usuarios de FashionHub
('u2222222-2222-2222-2222-222222222221', '22222222-2222-2222-2222-222222222222', NULL,
 'admin@fashionhub.com', '$2b$10$abcdefghijklmnopqrstuvwxyz123456', 'TENANT_ADMIN', 'ACTIVE', NOW() - INTERVAL '4 hours', NOW() - INTERVAL '3 months'),

('u2222222-2222-2222-2222-222222222222', '22222222-2222-2222-2222-222222222222', 'a2222222-2222-2222-2222-222222222221',
 'manager.unicentro@fashionhub.com', '$2b$10$abcdefghijklmnopqrstuvwxyz123456', 'MANAGER', 'ACTIVE', NOW() - INTERVAL '2 hours', NOW() - INTERVAL '3 months'),

-- Usuario de MercadoLocal
('u3333333-3333-3333-3333-333333333331', '33333333-3333-3333-3333-333333333333', 'a3333333-3333-3333-3333-333333333331',
 'admin@mercadolocal.com', '$2b$10$abcdefghijklmnopqrstuvwxyz123456', 'TENANT_ADMIN', 'ACTIVE', NOW() - INTERVAL '5 hours', NOW() - INTERVAL '1 month');

-- =====================================================
-- 4. PRODUCTS_CONSOLIDATED (Catálogo de Productos)
-- =====================================================

-- Productos de TechStore (Tecnología)
INSERT INTO products_consolidated (id, tenant_id, sku, name, description, category, price, cost, unit, metadata, version, created_at) VALUES
('p1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111',
 'LAP-HP-001', 'Laptop HP Pavilion 15', 'Laptop HP Pavilion 15.6", Intel i5, 8GB RAM, 256GB SSD', 'Laptops', 2500000.00, 1800000.00, 'UNIT',
 '{"brand": "HP", "warranty": "12 months", "images": ["laptop-hp-001.jpg"]}'::jsonb, 1, NOW() - INTERVAL '6 months'),

('p1111111-1111-1111-1111-111111111112', '11111111-1111-1111-1111-111111111111',
 'LAP-DEL-001', 'Laptop Dell Inspiron 14', 'Laptop Dell Inspiron 14", Intel i7, 16GB RAM, 512GB SSD', 'Laptops', 3200000.00, 2400000.00, 'UNIT',
 '{"brand": "Dell", "warranty": "12 months", "images": ["laptop-dell-001.jpg"]}'::jsonb, 1, NOW() - INTERVAL '6 months'),

('p1111111-1111-1111-1111-111111111113', '11111111-1111-1111-1111-111111111111',
 'MOU-LOG-001', 'Mouse Logitech MX Master 3', 'Mouse inalámbrico ergonómico Logitech MX Master 3', 'Accesorios', 350000.00, 220000.00, 'UNIT',
 '{"brand": "Logitech", "warranty": "24 months", "wireless": true}'::jsonb, 1, NOW() - INTERVAL '5 months'),

('p1111111-1111-1111-1111-111111111114', '11111111-1111-1111-1111-111111111111',
 'KEY-COR-001', 'Teclado Corsair K70', 'Teclado mecánico RGB Corsair K70', 'Accesorios', 450000.00, 300000.00, 'UNIT',
 '{"brand": "Corsair", "warranty": "24 months", "mechanical": true, "rgb": true}'::jsonb, 1, NOW() - INTERVAL '5 months'),

('p1111111-1111-1111-1111-111111111115', '11111111-1111-1111-1111-111111111111',
 'MON-SAM-001', 'Monitor Samsung 27" 4K', 'Monitor Samsung 27 pulgadas, resolución 4K UHD', 'Monitores', 1200000.00, 850000.00, 'UNIT',
 '{"brand": "Samsung", "warranty": "36 months", "resolution": "3840x2160"}'::jsonb, 1, NOW() - INTERVAL '4 months'),

-- Productos de FashionHub (Ropa)
('p2222222-2222-2222-2222-222222222221', '22222222-2222-2222-2222-222222222222',
 'CAM-HOM-001', 'Camisa Hombre Formal Blanca', 'Camisa formal para hombre, color blanco, talla M', 'Ropa Hombre', 89000.00, 45000.00, 'UNIT',
 '{"sizes": ["S", "M", "L", "XL"], "color": "white", "material": "cotton"}'::jsonb, 1, NOW() - INTERVAL '3 months'),

('p2222222-2222-2222-2222-222222222222', '22222222-2222-2222-2222-222222222222',
 'PAN-MUJ-001', 'Pantalón Jean Mujer', 'Pantalón jean para mujer, corte skinny', 'Ropa Mujer', 120000.00, 60000.00, 'UNIT',
 '{"sizes": ["XS", "S", "M", "L"], "color": "blue", "material": "denim"}'::jsonb, 1, NOW() - INTERVAL '3 months'),

('p2222222-2222-2222-2222-222222222223', '22222222-2222-2222-2222-222222222222',
 'ZAP-DEP-001', 'Zapatos Deportivos Nike', 'Zapatos deportivos Nike Air Max', 'Calzado', 280000.00, 180000.00, 'UNIT',
 '{"brand": "Nike", "sizes": ["38", "39", "40", "41", "42"], "color": "black"}'::jsonb, 1, NOW() - INTERVAL '2 months'),

-- Productos de MercadoLocal (Abarrotes)
('p3333333-3333-3333-3333-333333333331', '33333333-3333-3333-3333-333333333333',
 'ARR-DIA-001', 'Arroz Diana x 500g', 'Arroz blanco Diana, empaque de 500 gramos', 'Abarrotes', 2500.00, 1800.00, 'UNIT',
 '{"brand": "Diana", "weight": "500g"}'::jsonb, 1, NOW() - INTERVAL '1 month'),

('p3333333-3333-3333-3333-333333333332', '33333333-3333-3333-3333-333333333333',
 'ACE-OLI-001', 'Aceite Oliva x 1L', 'Aceite de oliva extra virgen, botella de 1 litro', 'Abarrotes', 35000.00, 22000.00, 'LITER',
 '{"brand": "Carbonell", "volume": "1L"}'::jsonb, 1, NOW() - INTERVAL '1 month');

-- =====================================================
-- 5. INVENTORY_CONSOLIDATED (Stock por Sede)
-- =====================================================

-- Inventario TechStore Centro
INSERT INTO inventory_consolidated (id, tenant_id, sede_id, product_id, quantity, min_stock, max_stock, last_sync_at) VALUES
('i1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'p1111111-1111-1111-1111-111111111111', 15, 5, 30, NOW() - INTERVAL '5 minutes'),
('i1111111-1111-1111-1111-111111111112', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'p1111111-1111-1111-1111-111111111112', 8, 3, 20, NOW() - INTERVAL '5 minutes'),
('i1111111-1111-1111-1111-111111111113', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'p1111111-1111-1111-1111-111111111113', 45, 10, 100, NOW() - INTERVAL '5 minutes'),
('i1111111-1111-1111-1111-111111111114', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'p1111111-1111-1111-1111-111111111114', 32, 10, 80, NOW() - INTERVAL '5 minutes'),
('i1111111-1111-1111-1111-111111111115', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'p1111111-1111-1111-1111-111111111115', 12, 5, 25, NOW() - INTERVAL '5 minutes'),

-- Inventario TechStore Norte
('i1111111-1111-1111-1111-222222222221', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111112', 'p1111111-1111-1111-1111-111111111111', 22, 5, 30, NOW() - INTERVAL '10 minutes'),
('i1111111-1111-1111-1111-222222222222', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111112', 'p1111111-1111-1111-1111-111111111112', 12, 3, 20, NOW() - INTERVAL '10 minutes'),
('i1111111-1111-1111-1111-222222222223', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111112', 'p1111111-1111-1111-1111-111111111113', 67, 10, 100, NOW() - INTERVAL '10 minutes'),
('i1111111-1111-1111-1111-222222222224', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111112', 'p1111111-1111-1111-1111-111111111115', 8, 5, 25, NOW() - INTERVAL '10 minutes'),

-- Inventario TechStore Sur
('i1111111-1111-1111-1111-333333333331', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111113', 'p1111111-1111-1111-1111-111111111111', 3, 5, 30, NOW() - INTERVAL '15 minutes'), -- Bajo stock!
('i1111111-1111-1111-1111-333333333332', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111113', 'p1111111-1111-1111-1111-111111111113', 28, 10, 100, NOW() - INTERVAL '15 minutes'),
('i1111111-1111-1111-1111-333333333333', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111113', 'p1111111-1111-1111-1111-111111111114', 55, 10, 80, NOW() - INTERVAL '15 minutes'),

-- Inventario FashionHub Unicentro
('i2222222-2222-2222-2222-111111111111', '22222222-2222-2222-2222-222222222222', 'a2222222-2222-2222-2222-222222222221', 'p2222222-2222-2222-2222-222222222221', 120, 20, 200, NOW() - INTERVAL '8 minutes'),
('i2222222-2222-2222-2222-111111111112', '22222222-2222-2222-2222-222222222222', 'a2222222-2222-2222-2222-222222222221', 'p2222222-2222-2222-2222-222222222222', 85, 15, 150, NOW() - INTERVAL '8 minutes'),
('i2222222-2222-2222-2222-111111111113', '22222222-2222-2222-2222-222222222222', 'a2222222-2222-2222-2222-222222222221', 'p2222222-2222-2222-2222-222222222223', 45, 10, 80, NOW() - INTERVAL '8 minutes'),

-- Inventario FashionHub Andino
('i2222222-2222-2222-2222-222222222221', '22222222-2222-2222-2222-222222222222', 'a2222222-2222-2222-2222-222222222222', 'p2222222-2222-2222-2222-222222222221', 95, 20, 200, NOW() - INTERVAL '20 minutes'),
('i2222222-2222-2222-2222-222222222222', '22222222-2222-2222-2222-222222222222', 'a2222222-2222-2222-2222-222222222222', 'p2222222-2222-2222-2222-222222222222', 110, 15, 150, NOW() - INTERVAL '20 minutes'),

-- Inventario MercadoLocal
('i3333333-3333-3333-3333-111111111111', '33333333-3333-3333-3333-333333333333', 'a3333333-3333-3333-3333-333333333331', 'p3333333-3333-3333-3333-333333333331', 450, 100, 1000, NOW() - INTERVAL '30 minutes'),
('i3333333-3333-3333-3333-111111111112', '33333333-3333-3333-3333-333333333333', 'a3333333-3333-3333-3333-333333333331', 'p3333333-3333-3333-3333-333333333332', 78, 20, 150, NOW() - INTERVAL '30 minutes');

-- =====================================================
-- 6. TRANSACTIONS_LOG (Historial de Transacciones)
-- =====================================================

-- Transacciones TechStore Centro (últimos días)
INSERT INTO transactions_log (id, tenant_id, sede_id, product_id, user_id, type, quantity, reason, timestamp, synced_at) VALUES
-- Entrada de inventario inicial
('t1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'p1111111-1111-1111-1111-111111111111', 'u1111111-1111-1111-1111-111111111112', 'IN', 20, 'Compra inicial de inventario', NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),
('t1111111-1111-1111-1111-111111111112', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'p1111111-1111-1111-1111-111111111113', 'u1111111-1111-1111-1111-111111111112', 'IN', 50, 'Compra inicial de inventario', NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),

-- Ventas
('t1111111-1111-1111-1111-111111111113', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'p1111111-1111-1111-1111-111111111111', 'u1111111-1111-1111-1111-111111111113', 'OUT', -3, 'Venta a cliente', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
('t1111111-1111-1111-1111-111111111114', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'p1111111-1111-1111-1111-111111111113', 'u1111111-1111-1111-1111-111111111113', 'OUT', -5, 'Venta a cliente', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
('t1111111-1111-1111-1111-111111111115', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'p1111111-1111-1111-1111-111111111112', 'u1111111-1111-1111-1111-111111111113', 'OUT', -2, 'Venta a cliente', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),

-- Ajuste de inventario
('t1111111-1111-1111-1111-111111111116', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'p1111111-1111-1111-1111-111111111112', 'u1111111-1111-1111-1111-111111111112', 'ADJUSTMENT', -2, 'Ajuste por inventario físico - productos dañados', NOW() - INTERVAL '12 hours', NOW() - INTERVAL '12 hours'),

-- Transacciones TechStore Norte
('t1111111-1111-1111-1111-222222222221', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111112', 'p1111111-1111-1111-1111-111111111111', 'u1111111-1111-1111-1111-111111111114', 'IN', 25, 'Compra de inventario', NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),
('t1111111-1111-1111-1111-222222222222', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111112', 'p1111111-1111-1111-1111-111111111111', 'u1111111-1111-1111-1111-111111111114', 'OUT', -3, 'Venta a cliente', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),

-- Transacciones FashionHub
('t2222222-2222-2222-2222-111111111111', '22222222-2222-2222-2222-222222222222', 'a2222222-2222-2222-2222-222222222221', 'p2222222-2222-2222-2222-222222222221', 'u2222222-2222-2222-2222-222222222222', 'IN', 150, 'Compra de temporada', NOW() - INTERVAL '10 days', NOW() - INTERVAL '10 days'),
('t2222222-2222-2222-2222-111111111112', '22222222-2222-2222-2222-222222222222', 'a2222222-2222-2222-2222-222222222221', 'p2222222-2222-2222-2222-222222222221', 'u2222222-2222-2222-2222-222222222222', 'OUT', -30, 'Ventas del día', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day');

-- =====================================================
-- 7. TRANSFERS (Transferencias entre Sedes)
-- =====================================================

-- Transferencia completada: TechStore Norte → TechStore Sur
INSERT INTO transfers (id, tenant_id, from_sede_id, to_sede_id, product_id, requested_by, approved_by, quantity, status, requested_at, approved_at, completed_at, metadata) VALUES
('tf111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 
 'a1111111-1111-1111-1111-111111111112', -- TechStore Norte (origen)
 'a1111111-1111-1111-1111-111111111113', -- TechStore Sur (destino)
 'p1111111-1111-1111-1111-111111111111', -- Laptop HP
 'u1111111-1111-1111-1111-111111111115', -- Solicitado por vendedor Sur
 'u1111111-1111-1111-1111-111111111114', -- Aprobado por manager Norte
 5, 'COMPLETED', 
 NOW() - INTERVAL '2 days', 
 NOW() - INTERVAL '2 days' + INTERVAL '30 minutes',
 NOW() - INTERVAL '2 days' + INTERVAL '1 hour',
 '{"notes": "Transferencia urgente por bajo stock en sede Sur", "transport": "Mensajería interna"}'::jsonb),

-- Transferencia pendiente de aprobación
('tf111111-1111-1111-1111-111111111112', '11111111-1111-1111-1111-111111111111',
 'a1111111-1111-1111-1111-111111111111', -- TechStore Centro (origen)
 'a1111111-1111-1111-1111-111111111113', -- TechStore Sur (destino)
 'p1111111-1111-1111-1111-111111111114', -- Teclado Corsair
 'u1111111-1111-1111-1111-111111111115', -- Solicitado por vendedor Sur
 NULL, -- Aún no aprobado
 10, 'PENDING',
 NOW() - INTERVAL '3 hours',
 NULL, NULL,
 '{"notes": "Solicitud para reposición de stock"}'::jsonb),

-- Transferencia rechazada
('tf111111-1111-1111-1111-111111111113', '11111111-1111-1111-1111-111111111111',
 'a1111111-1111-1111-1111-111111111111', -- TechStore Centro (origen)
 'a1111111-1111-1111-1111-111111111112', -- TechStore Norte (destino)
 'p1111111-1111-1111-1111-111111111115', -- Monitor Samsung
 'u1111111-1111-1111-1111-111111111114', -- Solicitado por manager Norte
 'u1111111-1111-1111-1111-111111111112', -- Rechazado por manager Centro
 8, 'REJECTED',
 NOW() - INTERVAL '1 day',
 NOW() - INTERVAL '1 day' + INTERVAL '2 hours',
 NULL,
 '{"notes": "Solicitud rechazada"}'::jsonb);

-- Actualizar transfer_id en transacciones relacionadas con la transferencia completada
UPDATE transactions_log SET transfer_id = 'tf111111-1111-1111-1111-111111111111'
WHERE id IN (
  -- Crear las transacciones de la transferencia completada
  INSERT INTO transactions_log (id, tenant_id, sede_id, product_id, user_id, type, quantity, reason, transfer_id, timestamp, synced_at) VALUES
  -- Salida de TechStore Norte
  ('t1111111-1111-1111-1111-999999999991', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111112', 'p1111111-1111-1111-1111-111111111111', 'u1111111-1111-1111-1111-111111111114', 'TRANSFER_OUT', -5, 'Transferencia a TechStore Sur', 'tf111111-1111-1111-1111-111111111111', NOW() - INTERVAL '2 days' + INTERVAL '1 hour', NOW() - INTERVAL '2 days' + INTERVAL '1 hour'),
  -- Entrada a TechStore Sur
  ('t1111111-1111-1111-1111-999999999992', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111113', 'p1111111-1111-1111-1111-111111111111', 'u1111111-1111-1111-1111-111111111115', 'TRANSFER_IN', 5, 'Recepción desde TechStore Norte', 'tf111111-1111-1111-1111-111111111111', NOW() - INTERVAL '2 days' + INTERVAL '1 hour', NOW() - INTERVAL '2 days' + INTERVAL '1 hour')
  RETURNING id
);

-- =====================================================
-- 8. AUDIT_LOGS (Registros de Auditoría)
-- =====================================================

INSERT INTO audit_logs (id, tenant_id, user_id, sede_id, action, entity_type, entity_id, metadata, ip_address, timestamp) VALUES
-- Creación de productos
('al111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'u1111111-1111-1111-1111-111111111111', NULL, 'CREATE', 'PRODUCT', 'p1111111-1111-1111-1111-111111111111', '{"product_name": "Laptop HP Pavilion 15", "sku": "LAP-HP-001"}'::jsonb, '192.168.1.100', NOW() - INTERVAL '6 months'),

-- Aprobación de transferencia
('al111111-1111-1111-1111-111111111112', '11111111-1111-1111-1111-111111111111', 'u1111111-1111-1111-1111-111111111114', 'a1111111-1111-1111-1111-111111111112', 'UPDATE', 'TRANSFER', 'tf111111-1111-1111-1111-111111111111', '{"action": "approved", "from": "PENDING", "to": "APPROVED", "quantity": 5, "product": "Laptop HP Pavilion 15"}'::jsonb, '192.168.1.105', NOW() - INTERVAL '2 days' + INTERVAL '30 minutes'),

-- Rechazo de transferencia
('al111111-1111-1111-1111-111111111113', '11111111-1111-1111-1111-111111111111', 'u1111111-1111-1111-1111-111111111112', 'a1111111-1111-1111-1111-111111111111', 'UPDATE', 'TRANSFER', 'tf111111-1111-1111-1111-111111111113', '{"action": "rejected", "from": "PENDING", "to": "REJECTED", "reason": "Stock insuficiente en sede origen"}'::jsonb, '192.168.1.102', NOW() - INTERVAL '1 day' + INTERVAL '2 hours'),

-- Ajuste de inventario
('al111111-1111-1111-1111-111111111114', '11111111-1111-1111-1111-111111111111', 'u1111111-1111-1111-1111-111111111112', 'a1111111-1111-1111-1111-111111111111', 'UPDATE', 'INVENTORY', 'i1111111-1111-1111-1111-111111111112', '{"before": {"quantity": 10}, "after": {"quantity": 8}, "reason": "Ajuste por inventario físico - productos dañados"}'::jsonb, '192.168.1.102', NOW() - INTERVAL '12 hours'),

-- Login de usuario
('al111111-1111-1111-1111-111111111115', '11111111-1111-1111-1111-111111111111', 'u1111111-1111-1111-1111-111111111113', 'a1111111-1111-1111-1111-111111111111', 'SYNC', 'USER', 'u1111111-1111-1111-1111-111111111113', '{"action": "login", "user_agent": "Mozilla/5.0"}'::jsonb, '192.168.1.110', NOW() - INTERVAL '30 minutes');

-- =====================================================
-- VERIFICACIÓN DE DATOS
-- =====================================================

-- Mostrar resumen de datos insertados
DO $$
BEGIN
    RAISE NOTICE '=== RESUMEN DE DATOS INSERTADOS ===';
    RAISE NOTICE 'Tenants: %', (SELECT COUNT(*) FROM tenants);
    RAISE NOTICE 'Sedes: %', (SELECT COUNT(*) FROM sedes);
    RAISE NOTICE 'Usuarios: %', (SELECT COUNT(*) FROM users);
    RAISE NOTICE 'Productos: %', (SELECT COUNT(*) FROM products_consolidated);
    RAISE NOTICE 'Registros de Inventario: %', (SELECT COUNT(*) FROM inventory_consolidated);
    RAISE NOTICE 'Transacciones: %', (SELECT COUNT(*) FROM transactions_log);
    RAISE NOTICE 'Transferencias: %', (SELECT COUNT(*) FROM transfers);
    RAISE NOTICE 'Logs de Auditoría: %', (SELECT COUNT(*) FROM audit_logs);
    RAISE NOTICE '====================================';
END $$;

-- =====================================================
-- FIN DEL SCRIPT DE SEED DATA
-- =====================================================
