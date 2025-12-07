-- 03_triggers_logging.sql

-- Триггер для CUSTOMERS
CREATE OR REPLACE TRIGGER trg_log_customers
AFTER INSERT OR UPDATE OR DELETE ON customers
FOR EACH ROW
DECLARE
    v_op_type VARCHAR2(10);
    v_rec_id  NUMBER;
    v_json    CLOB;
BEGIN
    IF INSERTING THEN
        v_op_type := 'INSERT';
        v_rec_id  := :NEW.cust_id;
    ELSIF UPDATING THEN
        v_op_type := 'UPDATE';
        v_rec_id  := :OLD.cust_id;
        v_json := JSON_OBJECT('cust_id' VALUE :OLD.cust_id, 'name' VALUE :OLD.name, 'email' VALUE :OLD.email);
    ELSIF DELETING THEN
        v_op_type := 'DELETE';
        v_rec_id  := :OLD.cust_id;
        v_json := JSON_OBJECT('cust_id' VALUE :OLD.cust_id, 'name' VALUE :OLD.name, 'email' VALUE :OLD.email);
    END IF;

    INSERT INTO operation_logs (table_name, record_id, operation_type, old_value_json)
    VALUES ('CUSTOMERS', v_rec_id, v_op_type, v_json);
END;
/

-- Триггер для ORDERS
CREATE OR REPLACE TRIGGER trg_log_orders
AFTER INSERT OR UPDATE OR DELETE ON orders
FOR EACH ROW
DECLARE
    v_op_type VARCHAR2(10);
    v_rec_id  NUMBER;
    v_json    CLOB;
BEGIN
    IF INSERTING THEN
        v_op_type := 'INSERT';
        v_rec_id  := :NEW.order_id;
    ELSIF UPDATING THEN
        v_op_type := 'UPDATE';
        v_rec_id  := :OLD.order_id;
        v_json := JSON_OBJECT('order_id' VALUE :OLD.order_id, 'cust_id' VALUE :OLD.cust_id, 
                              'order_date' VALUE TO_CHAR(:OLD.order_date, 'YYYY-MM-DD HH24:MI:SS'), 'status' VALUE :OLD.status);
    ELSIF DELETING THEN
        v_op_type := 'DELETE';
        v_rec_id  := :OLD.order_id;
        v_json := JSON_OBJECT('order_id' VALUE :OLD.order_id, 'cust_id' VALUE :OLD.cust_id, 
                              'order_date' VALUE TO_CHAR(:OLD.order_date, 'YYYY-MM-DD HH24:MI:SS'), 'status' VALUE :OLD.status);
    END IF;

    INSERT INTO operation_logs (table_name, record_id, operation_type, old_value_json)
    VALUES ('ORDERS', v_rec_id, v_op_type, v_json);
END;
/

-- Триггер для ORDER_ITEMS
CREATE OR REPLACE TRIGGER trg_log_items
AFTER INSERT OR UPDATE OR DELETE ON order_items
FOR EACH ROW
DECLARE
    v_op_type VARCHAR2(10);
    v_rec_id  NUMBER;
    v_json    CLOB;
BEGIN
    IF INSERTING THEN
        v_op_type := 'INSERT';
        v_rec_id  := :NEW.item_id;
    ELSIF UPDATING THEN
        v_op_type := 'UPDATE';
        v_rec_id  := :OLD.item_id;
        v_json := JSON_OBJECT('item_id' VALUE :OLD.item_id, 'order_id' VALUE :OLD.order_id, 
                              'product_name' VALUE :OLD.product_name, 'quantity' VALUE :OLD.quantity, 'price' VALUE :OLD.price);
    ELSIF DELETING THEN
        v_op_type := 'DELETE';
        v_rec_id  := :OLD.item_id;
        v_json := JSON_OBJECT('item_id' VALUE :OLD.item_id, 'order_id' VALUE :OLD.order_id, 
                              'product_name' VALUE :OLD.product_name, 'quantity' VALUE :OLD.quantity, 'price' VALUE :OLD.price);
    END IF;

    INSERT INTO operation_logs (table_name, record_id, operation_type, old_value_json)
    VALUES ('ORDER_ITEMS', v_rec_id, v_op_type, v_json);
END;
/