-- Сначала удалим старую версию, чтобы точно обновились типы
DROP PACKAGE BODY pkg_admin_tools;
DROP PACKAGE pkg_admin_tools;

CREATE OR REPLACE PACKAGE pkg_admin_tools AS
    PROCEDURE get_logs(p_date_from TIMESTAMP DEFAULT NULL, p_date_to TIMESTAMP DEFAULT NULL, p_op_type VARCHAR2 DEFAULT NULL, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE revert_operation(p_log_id NUMBER);
    
    -- ИЗМЕНЕНИЕ: Параметры теперь VARCHAR2 ('Y' или 'N')
    PROCEDURE get_summary_report(
        p_sort_entity VARCHAR2, 
        p_sort_type   VARCHAR2, 
        p_sort_count  VARCHAR2, 
        p_cursor OUT SYS_REFCURSOR
    );
END pkg_admin_tools;
/

CREATE OR REPLACE PACKAGE BODY pkg_admin_tools AS

    PROCEDURE get_logs(
        p_date_from TIMESTAMP DEFAULT NULL,
        p_date_to TIMESTAMP DEFAULT NULL,
        p_op_type VARCHAR2 DEFAULT NULL,
        p_cursor OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN p_cursor FOR
            SELECT * FROM operation_logs
            WHERE (p_date_from IS NULL OR operation_date >= p_date_from)
              AND (p_date_to IS NULL OR operation_date <= p_date_to)
              AND (p_op_type IS NULL OR operation_type = p_op_type)
            ORDER BY operation_date DESC;
    END;

    PROCEDURE revert_operation(p_log_id NUMBER) IS
        v_log_row operation_logs%ROWTYPE;
    BEGIN
        SELECT * INTO v_log_row FROM operation_logs WHERE log_id = p_log_id;
        
        IF v_log_row.reverted = 'Y' THEN
            RAISE_APPLICATION_ERROR(-20001, 'Эта операция уже была отменена.');
        END IF;
        
        -- Логика отката
        IF v_log_row.operation_type = 'INSERT' THEN
            EXECUTE IMMEDIATE 'DELETE FROM ' || v_log_row.table_name || 
                              ' WHERE ' || CASE v_log_row.table_name 
                                           WHEN 'CUSTOMERS' THEN 'cust_id'
                                           WHEN 'ORDERS' THEN 'order_id'
                                           WHEN 'ORDER_ITEMS' THEN 'item_id'
                                           END || ' = :1' 
            USING v_log_row.record_id;

        ELSIF v_log_row.operation_type = 'DELETE' THEN
             IF v_log_row.table_name = 'CUSTOMERS' THEN
                INSERT INTO customers (cust_id, name, email) VALUES 
                (JSON_VALUE(v_log_row.old_value_json, '$.cust_id'), JSON_VALUE(v_log_row.old_value_json, '$.name'), JSON_VALUE(v_log_row.old_value_json, '$.email'));
            ELSIF v_log_row.table_name = 'ORDERS' THEN
                INSERT INTO orders (order_id, cust_id, order_date, status) VALUES 
                (JSON_VALUE(v_log_row.old_value_json, '$.order_id'), JSON_VALUE(v_log_row.old_value_json, '$.cust_id'), TO_DATE(JSON_VALUE(v_log_row.old_value_json, '$.order_date'), 'YYYY-MM-DD HH24:MI:SS'), JSON_VALUE(v_log_row.old_value_json, '$.status'));
            ELSIF v_log_row.table_name = 'ORDER_ITEMS' THEN
                INSERT INTO order_items (item_id, order_id, product_name, quantity, price) VALUES 
                (JSON_VALUE(v_log_row.old_value_json, '$.item_id'), JSON_VALUE(v_log_row.old_value_json, '$.order_id'), JSON_VALUE(v_log_row.old_value_json, '$.product_name'), JSON_VALUE(v_log_row.old_value_json, '$.quantity'), JSON_VALUE(v_log_row.old_value_json, '$.price'));
            END IF;

        ELSIF v_log_row.operation_type = 'UPDATE' THEN
            IF v_log_row.table_name = 'CUSTOMERS' THEN
                UPDATE customers SET name = JSON_VALUE(v_log_row.old_value_json, '$.name'), email = JSON_VALUE(v_log_row.old_value_json, '$.email') WHERE cust_id = v_log_row.record_id;
            ELSIF v_log_row.table_name = 'ORDERS' THEN
                UPDATE orders SET cust_id = JSON_VALUE(v_log_row.old_value_json, '$.cust_id'), order_date = TO_DATE(JSON_VALUE(v_log_row.old_value_json, '$.order_date'), 'YYYY-MM-DD HH24:MI:SS'), status = JSON_VALUE(v_log_row.old_value_json, '$.status') WHERE order_id = v_log_row.record_id;
            ELSIF v_log_row.table_name = 'ORDER_ITEMS' THEN
                UPDATE order_items SET quantity = JSON_VALUE(v_log_row.old_value_json, '$.quantity'), price = JSON_VALUE(v_log_row.old_value_json, '$.price') WHERE item_id = v_log_row.record_id;
            END IF;
        END IF;

        UPDATE operation_logs SET reverted = 'Y' WHERE log_id = p_log_id;
        COMMIT;
    EXCEPTION WHEN OTHERS THEN ROLLBACK; RAISE;
    END;

    -- ИЗМЕНЕНИЕ: Работаем со строками 'Y'
    PROCEDURE get_summary_report(
        p_sort_entity VARCHAR2, 
        p_sort_type   VARCHAR2, 
        p_sort_count  VARCHAR2, 
        p_cursor OUT SYS_REFCURSOR
    ) IS
        v_sql VARCHAR2(4000);
        v_order_by VARCHAR2(1000) := '';
    BEGIN
        v_sql := 'SELECT table_name, operation_type, COUNT(*) as op_count FROM operation_logs GROUP BY table_name, operation_type';
        
        -- Проверка на 'Y' (работает железобетонно)
        IF p_sort_entity = 'Y' THEN v_order_by := v_order_by || 'table_name, '; END IF;
        IF p_sort_type   = 'Y' THEN v_order_by := v_order_by || 'operation_type, '; END IF;
        IF p_sort_count  = 'Y' THEN v_order_by := v_order_by || 'op_count DESC, '; END IF;
        
        IF v_order_by IS NOT NULL THEN
            v_sql := v_sql || ' ORDER BY ' || RTRIM(v_order_by, ', ');
        END IF;

        OPEN p_cursor FOR v_sql;
    END;
END pkg_admin_tools;
/