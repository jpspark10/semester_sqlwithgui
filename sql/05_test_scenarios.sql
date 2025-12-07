SET SERVEROUTPUT ON;
DECLARE
    v_cust_id NUMBER;
    v_order_id NUMBER;
    v_item_id NUMBER;
    v_cur SYS_REFCURSOR;
    v_table VARCHAR2(50);
    v_op VARCHAR2(50);
    v_cnt NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- 1. Создание тестовых данных ---');
    pkg_shop_operations.add_customer('Ivan Ivanov', 'ivan@test.com', v_cust_id);
    pkg_shop_operations.add_order(v_cust_id, 'NEW', v_order_id);
    pkg_shop_operations.add_item(v_order_id, 'Laptop', 1, 1000, v_item_id);
    
    DBMS_OUTPUT.PUT_LINE('--- 2. Изменение данных ---');
    pkg_shop_operations.upd_item(v_item_id, 2, 950); 
    
    DBMS_OUTPUT.PUT_LINE('--- 3. Удаление данных ---');
    pkg_shop_operations.del_item(v_item_id); 
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('--- 4. Просмотр лога операций ---');
    FOR r IN (SELECT * FROM operation_logs ORDER BY log_id) LOOP
        DBMS_OUTPUT.PUT_LINE('Log ID ' || r.log_id || ': ' || r.operation_type || ' в таблице ' || r.table_name);
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('--- 5. Отчет о количестве операций ---');
    -- ИСПРАВЛЕНИЕ ЗДЕСЬ: Передаем 'Y' вместо TRUE и 'N' вместо FALSE
    pkg_admin_tools.get_summary_report('Y', 'Y', 'N', v_cur);
    
    LOOP
        FETCH v_cur INTO v_table, v_op, v_cnt;
        EXIT WHEN v_cur%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(v_table || ' | ' || v_op || ' : ' || v_cnt);
    END LOOP;
    CLOSE v_cur;

    DBMS_OUTPUT.PUT_LINE('--- 6. Тест отмены операции (Восстановление товара) ---');
    -- Находим удаление товара
    FOR r IN (SELECT log_id FROM operation_logs WHERE operation_type='DELETE' AND table_name='ORDER_ITEMS' AND rownum=1) LOOP
        DBMS_OUTPUT.PUT_LINE('Откатываем удаление, Log ID: ' || r.log_id);
        pkg_admin_tools.revert_operation(r.log_id);
    END LOOP;
    
    FOR r IN (SELECT * FROM order_items) LOOP
        DBMS_OUTPUT.PUT_LINE('Товар в базе: ' || r.product_name || ', цена: ' || r.price);
    END LOOP;
END;
/