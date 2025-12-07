-- 00_cleanup.sql
DROP TRIGGER trg_log_items;
DROP TRIGGER trg_log_orders;
DROP TRIGGER trg_log_customers;
DROP PACKAGE BODY pkg_admin_tools;
DROP PACKAGE pkg_admin_tools;
DROP PACKAGE BODY pkg_shop_operations;
DROP PACKAGE pkg_shop_operations;
DROP TABLE operation_logs;
DROP TABLE order_items;
DROP TABLE orders;
DROP TABLE customers;
DROP SEQUENCE seq_cust;
DROP SEQUENCE seq_order;
DROP SEQUENCE seq_item;
COMMIT;