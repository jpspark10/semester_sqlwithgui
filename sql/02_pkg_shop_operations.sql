-- 02_pkg_shop_operations.sql
CREATE OR REPLACE PACKAGE pkg_shop_operations AS
    PROCEDURE add_customer(p_name VARCHAR2, p_email VARCHAR2, p_out_id OUT NUMBER);
    PROCEDURE upd_customer(p_id NUMBER, p_name VARCHAR2, p_email VARCHAR2);
    PROCEDURE del_customer(p_id NUMBER);
    
    PROCEDURE add_order(p_cust_id NUMBER, p_status VARCHAR2, p_out_id OUT NUMBER);
    PROCEDURE upd_order(p_id NUMBER, p_status VARCHAR2);
    PROCEDURE del_order(p_id NUMBER);
    
    PROCEDURE add_item(p_order_id NUMBER, p_prod VARCHAR2, p_qty NUMBER, p_price NUMBER, p_out_id OUT NUMBER);
    PROCEDURE upd_item(p_id NUMBER, p_qty NUMBER, p_price NUMBER);
    PROCEDURE del_item(p_id NUMBER);
END pkg_shop_operations;
/

CREATE OR REPLACE PACKAGE BODY pkg_shop_operations AS
    -- Customers
    PROCEDURE add_customer(p_name VARCHAR2, p_email VARCHAR2, p_out_id OUT NUMBER) IS
    BEGIN
        INSERT INTO customers (cust_id, name, email) VALUES (seq_cust.NEXTVAL, p_name, p_email)
        RETURNING cust_id INTO p_out_id;
        COMMIT;
    END;

    PROCEDURE upd_customer(p_id NUMBER, p_name VARCHAR2, p_email VARCHAR2) IS
    BEGIN
        UPDATE customers SET name = p_name, email = p_email WHERE cust_id = p_id;
        COMMIT;
    END;

    PROCEDURE del_customer(p_id NUMBER) IS
    BEGIN
        DELETE FROM customers WHERE cust_id = p_id;
        COMMIT;
    END;

    -- Orders
    PROCEDURE add_order(p_cust_id NUMBER, p_status VARCHAR2, p_out_id OUT NUMBER) IS
    BEGIN
        INSERT INTO orders (order_id, cust_id, order_date, status)
        VALUES (seq_order.NEXTVAL, p_cust_id, SYSDATE, p_status)
        RETURNING order_id INTO p_out_id;
        COMMIT;
    END;

    PROCEDURE upd_order(p_id NUMBER, p_status VARCHAR2) IS
    BEGIN
        UPDATE orders SET status = p_status WHERE order_id = p_id;
        COMMIT;
    END;

    PROCEDURE del_order(p_id NUMBER) IS
    BEGIN
        DELETE FROM orders WHERE order_id = p_id;
        COMMIT;
    END;

    -- Items
    PROCEDURE add_item(p_order_id NUMBER, p_prod VARCHAR2, p_qty NUMBER, p_price NUMBER, p_out_id OUT NUMBER) IS
    BEGIN
        INSERT INTO order_items (item_id, order_id, product_name, quantity, price)
        VALUES (seq_item.NEXTVAL, p_order_id, p_prod, p_qty, p_price)
        RETURNING item_id INTO p_out_id;
        COMMIT;
    END;

    PROCEDURE upd_item(p_id NUMBER, p_qty NUMBER, p_price NUMBER) IS
    BEGIN
        UPDATE order_items SET quantity = p_qty, price = p_price WHERE item_id = p_id;
        COMMIT;
    END;

    PROCEDURE del_item(p_id NUMBER) IS
    BEGIN
        DELETE FROM order_items WHERE item_id = p_id;
        COMMIT;
    END;
END pkg_shop_operations;
/