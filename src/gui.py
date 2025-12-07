import tkinter as tk
from tkinter import ttk, messagebox
from .database import ShopDatabase


class ShopApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Oracle Shop Manager")
        self.root.geometry("1000x650")  # Чуть увеличили окно

        self.db = ShopDatabase()

        try:
            self.db.connect()
            self.root.title("Oracle Shop Manager - [Connected]")
        except Exception as e:
            self._handle_error(e)
            self.root.destroy()
            return

        self._init_ui()

    def _init_ui(self):
        # Основной контейнер вкладок
        self.notebook = ttk.Notebook(self.root)
        self.notebook.pack(expand=True, fill='both')

        self.create_operations_tab()
        self.create_logs_tab()
        self.create_reports_tab()
        self.create_data_view_tab()  # <--- НОВАЯ ВКЛАДКА

    def _handle_error(self, exc):
        error_msg = str(exc)
        title = "Ошибка базы данных"
        if "ORA-02291" in error_msg:
            title = "Ошибка данных"
            error_msg = "Невозможно создать запись: указанный ID (Клиента или Заказа) не существует."
        elif "ORA-02292" in error_msg:
            title = "Запрещено удаление"
            error_msg = "Невозможно удалить запись, так как от неё зависят другие данные (например, у Клиента есть Заказы)."
        elif "PLS-00306" in error_msg or "ORA-06550" in error_msg:
            title = "Ошибка кода"
            error_msg = "Несовпадение типов параметров. Обновите SQL скрипты."
        elif "ORA-20001" in error_msg:
            title = "Операция невозможна"
            error_msg = "Эта операция уже была отменена ранее."
        messagebox.showerror(title, error_msg)

    # ===============================
    # 1. ВКЛАДКА ОПЕРАЦИЙ
    # ===============================
    def create_operations_tab(self):
        tab = ttk.Frame(self.notebook)
        self.notebook.add(tab, text="1. Операции (CRUD)")

        # --- Клиенты ---
        frame_cust = ttk.LabelFrame(tab, text="Добавить Клиента")
        frame_cust.pack(fill="x", padx=10, pady=5)
        ttk.Label(frame_cust, text="Имя:").pack(side="left", padx=5)
        self.ent_cust_name = ttk.Entry(frame_cust);
        self.ent_cust_name.pack(side="left")
        ttk.Label(frame_cust, text="Email:").pack(side="left", padx=5)
        self.ent_cust_email = ttk.Entry(frame_cust);
        self.ent_cust_email.pack(side="left")
        ttk.Button(frame_cust, text="Создать", command=self.on_add_customer).pack(side="left", padx=10)

        # --- Заказы ---
        frame_ord = ttk.LabelFrame(tab, text="Добавить Заказ")
        frame_ord.pack(fill="x", padx=10, pady=5)
        ttk.Label(frame_ord, text="ID Клиента:").pack(side="left", padx=5)
        self.ent_ord_cust_id = ttk.Entry(frame_ord, width=10);
        self.ent_ord_cust_id.pack(side="left")
        ttk.Label(frame_ord, text="Статус:").pack(side="left", padx=5)
        self.ent_ord_status = ttk.Entry(frame_ord, width=15);
        self.ent_ord_status.insert(0, "NEW");
        self.ent_ord_status.pack(side="left")
        ttk.Button(frame_ord, text="Создать", command=self.on_add_order).pack(side="left", padx=10)

        # --- Товары ---
        frame_item = ttk.LabelFrame(tab, text="Добавить Товар")
        frame_item.pack(fill="x", padx=10, pady=5)
        ttk.Label(frame_item, text="ID Заказа:").pack(side="left", padx=5)
        self.ent_item_ord_id = ttk.Entry(frame_item, width=10);
        self.ent_item_ord_id.pack(side="left")
        ttk.Label(frame_item, text="Товар:").pack(side="left", padx=5)
        self.ent_item_name = ttk.Entry(frame_item);
        self.ent_item_name.pack(side="left")
        ttk.Label(frame_item, text="Кол-во:").pack(side="left", padx=2)
        self.ent_item_qty = ttk.Entry(frame_item, width=5);
        self.ent_item_qty.pack(side="left")
        ttk.Label(frame_item, text="Цена:").pack(side="left", padx=2)
        self.ent_item_price = ttk.Entry(frame_item, width=8);
        self.ent_item_price.pack(side="left")
        ttk.Button(frame_item, text="Добавить", command=self.on_add_item).pack(side="left", padx=10)

        # --- Удаление ---
        frame_del = ttk.LabelFrame(tab, text="Удаление Товара")
        frame_del.pack(fill="x", padx=10, pady=5)
        ttk.Label(frame_del, text="ID Товара:").pack(side="left", padx=5)
        self.ent_del_id = ttk.Entry(frame_del, width=10);
        self.ent_del_id.pack(side="left")
        ttk.Button(frame_del, text="Удалить", command=self.on_del_item).pack(side="left", padx=10)

    # ===============================
    # 2. ВКЛАДКА ЛОГОВ
    # ===============================
    def create_logs_tab(self):
        tab = ttk.Frame(self.notebook)
        self.notebook.add(tab, text="2. Логи и Откат")

        fr = ttk.Frame(tab)
        fr.pack(fill="x", padx=10, pady=10)
        ttk.Button(fr, text="Обновить лог", command=self.on_load_logs).pack(side="left")
        ttk.Button(fr, text="ОТКАТИТЬ ВЫБРАННОЕ", command=self.on_revert).pack(side="right")

        cols = ("log_id", "table", "rec_id", "type", "date", "reverted")
        self.tree_logs = ttk.Treeview(tab, columns=cols, show="headings")
        self.tree_logs.heading("log_id", text="Log ID");
        self.tree_logs.column("log_id", width=50)
        self.tree_logs.heading("table", text="Table");
        self.tree_logs.column("table", width=100)
        self.tree_logs.heading("rec_id", text="Rec ID");
        self.tree_logs.column("rec_id", width=60)
        self.tree_logs.heading("type", text="Type");
        self.tree_logs.column("type", width=80)
        self.tree_logs.heading("date", text="Date")
        self.tree_logs.heading("reverted", text="Reverted?");
        self.tree_logs.column("reverted", width=60)

        self.tree_logs.pack(fill="both", expand=True, padx=10, pady=5)

    # ===============================
    # 3. ВКЛАДКА ОТЧЕТОВ
    # ===============================
    def create_reports_tab(self):
        tab = ttk.Frame(self.notebook)
        self.notebook.add(tab, text="3. Отчеты")

        fr = ttk.Frame(tab)
        fr.pack(fill="x", padx=10, pady=10)
        self.v_s1 = tk.BooleanVar(value=True)
        self.v_s2 = tk.BooleanVar(value=True)
        self.v_s3 = tk.BooleanVar(value=False)
        ttk.Checkbutton(fr, text="Сущность", variable=self.v_s1).pack(side="left")
        ttk.Checkbutton(fr, text="Тип операции", variable=self.v_s2).pack(side="left")
        ttk.Checkbutton(fr, text="Количество", variable=self.v_s3).pack(side="left")
        ttk.Button(fr, text="Сформировать", command=self.on_report).pack(side="left", padx=10)

        self.tree_rep = ttk.Treeview(tab, columns=("t", "ty", "c"), show="headings")
        self.tree_rep.heading("t", text="Table")
        self.tree_rep.heading("ty", text="Type")
        self.tree_rep.heading("c", text="Count")
        self.tree_rep.pack(fill="both", expand=True, padx=10, pady=5)

    # ===============================
    # 4. НОВАЯ ВКЛАДКА: ПРОСМОТР ДАННЫХ
    # ===============================
    def create_data_view_tab(self):
        tab = ttk.Frame(self.notebook)
        self.notebook.add(tab, text="4. Данные (Tables)")

        # Создаем еще один набор вкладок внутри (Sub-tabs)
        sub_notebook = ttk.Notebook(tab)
        sub_notebook.pack(expand=True, fill='both', padx=5, pady=5)

        # -- Вкладка Клиенты --
        self.tree_cust = self._create_table_tab(sub_notebook, "Клиенты", ["ID", "Name", "Email"],
                                                self.on_load_customers)
        # -- Вкладка Заказы --
        self.tree_ord = self._create_table_tab(sub_notebook, "Заказы", ["Order ID", "Client Name", "Date", "Status"],
                                               self.on_load_orders)
        # -- Вкладка Товары --
        self.tree_items = self._create_table_tab(sub_notebook, "Товары",
                                                 ["Item ID", "Order ID", "Product", "Qty", "Price"], self.on_load_items)

        # Кнопка "Обновить все" внизу
        ttk.Button(tab, text="Обновить все таблицы", command=self.on_refresh_all_data).pack(fill='x', padx=10, pady=5)

    def _create_table_tab(self, parent, title, columns, refresh_command):
        frame = ttk.Frame(parent)
        parent.add(frame, text=title)

        # Дерево
        tree = ttk.Treeview(frame, columns=columns, show="headings")
        for col in columns:
            tree.heading(col, text=col)
            tree.column(col, width=100)

        # Скроллбар
        y_scroll = ttk.Scrollbar(frame, orient="vertical", command=tree.yview)
        tree.configure(yscroll=y_scroll.set)

        y_scroll.pack(side="right", fill="y")
        tree.pack(side="left", fill="both", expand=True)

        return tree

    # ===============================
    # ОБРАБОТЧИКИ
    # ===============================
    def on_add_customer(self):
        try:
            new_id = self.db.add_customer(self.ent_cust_name.get(), self.ent_cust_email.get())
            messagebox.showinfo("OK", f"Клиент создан ID: {new_id}")
            self.on_refresh_all_data()  # Авто-обновление таблиц
        except Exception as e:
            self._handle_error(e)

    def on_add_order(self):
        try:
            cust_id = int(self.ent_ord_cust_id.get())
            new_id = self.db.add_order(cust_id, self.ent_ord_status.get())
            messagebox.showinfo("OK", f"Заказ создан ID: {new_id}")
            self.on_refresh_all_data()
        except Exception as e:
            self._handle_error(e)

    def on_add_item(self):
        try:
            ord_id = int(self.ent_item_ord_id.get())
            new_id = self.db.add_item(ord_id, self.ent_item_name.get(), int(self.ent_item_qty.get()),
                                      float(self.ent_item_price.get()))
            messagebox.showinfo("OK", f"Товар добавлен ID: {new_id}")
            self.on_refresh_all_data()
        except Exception as e:
            self._handle_error(e)

    def on_del_item(self):
        try:
            self.db.delete_item(int(self.ent_del_id.get()))
            messagebox.showinfo("OK", "Товар удален")
            self.on_refresh_all_data()
        except Exception as e:
            self._handle_error(e)

    def on_load_logs(self):
        self._fill_tree(self.tree_logs, self.db.get_logs())

    def on_revert(self):
        sel = self.tree_logs.selection()
        if not sel: return
        log_id = self.tree_logs.item(sel[0])['values'][0]
        try:
            self.db.revert_operation(log_id)
            messagebox.showinfo("OK", "Откат выполнен")
            self.on_load_logs()
            self.on_refresh_all_data()
        except Exception as e:
            self._handle_error(e)

    def on_report(self):
        self._fill_tree(self.tree_rep, self.db.get_summary(self.v_s1.get(), self.v_s2.get(), self.v_s3.get()))

    # --- Загрузка данных в таблицы ---
    def on_refresh_all_data(self):
        self.on_load_customers()
        self.on_load_orders()
        self.on_load_items()

    def on_load_customers(self):
        self._fill_tree(self.tree_cust, self.db.get_all_customers())

    def on_load_orders(self):
        self._fill_tree(self.tree_ord, self.db.get_all_orders())

    def on_load_items(self):
        self._fill_tree(self.tree_items, self.db.get_all_items())

    def _fill_tree(self, tree, rows):
        for i in tree.get_children(): tree.delete(i)
        for r in rows: tree.insert("", "end", values=r)