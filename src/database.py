import oracledb
from .config import DB_USER, DB_PASS, DB_DSN


class ShopDatabase:
    def __init__(self):
        self.conn = None

    def connect(self):
        """Создает подключение к БД"""
        try:
            self.conn = oracledb.connect(user=DB_USER, password=DB_PASS, dsn=DB_DSN)
            return True
        except oracledb.Error as e:
            raise Exception(f"Ошибка подключения: {e}")

    def disconnect(self):
        if self.conn:
            self.conn.close()

    def call_procedure_out_id(self, proc_name, params):
        """Вызывает процедуру, которая возвращает ID (для INSERT)"""
        cursor = self.conn.cursor()
        out_id = cursor.var(oracledb.NUMBER)
        # Добавляем output переменную в конец списка параметров
        full_params = params + [out_id]
        cursor.callproc(proc_name, full_params)
        return out_id.getvalue()

    def call_void_procedure(self, proc_name, params):
        """Вызывает процедуру без возвращаемых значений (DELETE, REVERT)"""
        cursor = self.conn.cursor()
        cursor.callproc(proc_name, params)

    def fetch_refcursor(self, proc_name, params):
        """Получает данные из процедуры, возвращающей SYS_REFCURSOR"""
        cursor = self.conn.cursor()
        ref_cursor = cursor.var(oracledb.CURSOR)
        full_params = params + [ref_cursor]

        cursor.callproc(proc_name, full_params)

        # Получаем данные из курсора
        return ref_cursor.getvalue().fetchall()

    # --- Методы-обертки для конкретных задач ---

    def add_customer(self, name, email):
        return self.call_procedure_out_id("pkg_shop_operations.add_customer", [name, email])

    def add_order(self, cust_id, status):
        return self.call_procedure_out_id("pkg_shop_operations.add_order", [cust_id, status])

    def add_item(self, order_id, product, qty, price):
        return self.call_procedure_out_id("pkg_shop_operations.add_item", [order_id, product, qty, price])

    def delete_item(self, item_id):
        self.call_void_procedure("pkg_shop_operations.del_item", [item_id])

    def get_logs(self):
        # Параметры NULL передаем как None
        return self.fetch_refcursor("pkg_admin_tools.get_logs", [None, None, None])

    def revert_operation(self, log_id):
        self.call_void_procedure("pkg_admin_tools.revert_operation", [log_id])

    def get_summary(self, sort_entity, sort_type, sort_count):
        # Преобразуем True/False -> 'Y'/'N'
        # Строки передаются драйвером Oracle без ошибок и зависаний
        p1 = 'Y' if sort_entity else 'N'
        p2 = 'Y' if sort_type else 'N'
        p3 = 'Y' if sort_count else 'N'

        return self.fetch_refcursor("pkg_admin_tools.get_summary_report", [p1, p2, p3])

    def get_all_customers(self):
        cursor = self.conn.cursor()
        cursor.execute("SELECT cust_id, name, email FROM customers ORDER BY cust_id DESC")
        return cursor.fetchall()

    def get_all_orders(self):
        cursor = self.conn.cursor()
        cursor.execute("""
            SELECT o.order_id, c.name, o.order_date, o.status 
            FROM orders o
            JOIN customers c ON o.cust_id = c.cust_id
            ORDER BY o.order_id DESC
        """)
        return cursor.fetchall()

    def get_all_items(self):
        cursor = self.conn.cursor()
        cursor.execute("""
            SELECT i.item_id, i.order_id, i.product_name, i.quantity, i.price 
            FROM order_items i
            ORDER BY i.item_id DESC
        """)
        return cursor.fetchall()