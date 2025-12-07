# Oracle DB Semester Project

## Project Structure

This project implements a shop database system with automatic logging and undo capabilities, managed via a Python GUI.

### Architecture Schema

```mermaid
graph TD
    subgraph Client [Python Client]
        Main[main.py] --> GUI[GUI Layer (src/gui.py)]
        GUI --> DB_Mgr[DB Manager (src/database.py)]
        DB_Mgr --> Config[Config (src/config.py)]
    end

    subgraph Driver [Network Layer]
        DB_Mgr -- oracledb driver --> Oracle[Oracle Database]
    end

    subgraph Server [Oracle Database 12c+]
        Oracle --> Pkg1[PKG_SHOP_OPERATIONS]
        Oracle --> Pkg2[PKG_ADMIN_TOOLS]
        
        Pkg1 --> Tables[(Data Tables)]
        Tables -- Triggers --> Logs[(Operation Logs)]
        
        Pkg2 -- Reads/Reverts --> Logs
        Pkg2 -- Modifies --> Tables
    end

    style Client fill:#e1f5fe,stroke:#01579b
    style Server fill:#fff3e0,stroke:#e65100
    style Tables fill:#dcedc8,stroke:#33691e
    style Logs fill:#ffcdd2,stroke:#b71c1c
```

## Setup Instructions

1. Run SQL scripts from `/sql` folder in order (00 -> 05).
2. Install python dependencies: `pip install -r requirements.txt`.
3. Configure credentials in `src/config.py`.
4. Run application: `python main.py`.