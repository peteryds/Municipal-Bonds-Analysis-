import psycopg2
import csv
import os
from psycopg2.extras import execute_values

# ================================
# DATABASE CONFIG
# ================================
DB_CONFIG = {
    "host": "localhost",
    "dbname": "test",
    "user": "koko"
}

DATA_DIR = "data"   # folder containing CSV files


# =================================================================
# Helper: Load CSV into table 
# =================================================================
def load_csv(conn, table_name, csv_filename):
    path = os.path.join(DATA_DIR, csv_filename)

    print(f"\nLoading {csv_filename} → {table_name} ...")

    # Columns that should NOT be inserted 
    identity_columns = {
        "trades": ["trade_id"],
        "economic_indicators": ["econ_id"]
    }

    try:
        with conn.cursor() as cur, open(path, "r", encoding="utf-8") as f:
            reader = csv.reader(f)
            header = next(reader)

            # Drop identity columns from header
            if table_name in identity_columns:
                header = [col for col in header if col not in identity_columns[table_name]]

            rows = []
            for row in reader:
                row_dict = dict(zip(next(csv.reader(open(path))), row))

                # Remove identity values
                clean_row = [None if r == "" else r for col, r in zip(row_dict.keys(), row_dict.values())
                             if col in header]

                rows.append(clean_row)

            sql = f"INSERT INTO {table_name} ({', '.join(header)}) VALUES %s"

            execute_values(cur, sql, rows)

        conn.commit()
        print(f"✓ Loaded {len(rows)} rows into {table_name}")

    except Exception as e:
        conn.rollback()
        print(f"✗ ERROR loading {table_name}: {e}")

# =================================================================
# Referential Integrity Checks
# =================================================================
def check_fk(conn, table, fk_column, ref_table, ref_column):
    with conn.cursor() as cur:
        query = f"""
            SELECT COUNT(*)
            FROM {table} t
            LEFT JOIN {ref_table} r
            ON t.{fk_column} = r.{ref_column}
            WHERE r.{ref_column} IS NULL;
        """
        cur.execute(query)
        missing = cur.fetchone()[0]

        if missing == 0:
            print(f"✓ FK OK: {table}.{fk_column} → {ref_table}.{ref_column}")
        else:
            print(f"✗ FK ERROR: {missing} missing references in {table}.{fk_column}")

def truncate_all_tables(conn):
    """Truncate all tables in FK-safe order before loading."""
    print("Truncating existing tables...")

    tables = [
        "credit_ratings",
        "trades",
        "bonds",
        "issuers",
        "bond_purposes",
        "economic_indicators"
    ]

    with conn.cursor() as cur:
        for t in tables:
            cur.execute(f"TRUNCATE TABLE {t} RESTART IDENTITY CASCADE;")
            print(f"✓ Truncated {t}")

    conn.commit()


# =================================================================
# Row Count Summary
# =================================================================
def print_row_counts(conn, tables):
    print("\n=== Row Counts ===")
    with conn.cursor() as cur:
        for t in tables:
            cur.execute(f"SELECT COUNT(*) FROM {t}")
            count = cur.fetchone()[0]
            print(f"{t}: {count:,d} rows")


# =================================================================
# MAIN SCRIPT
# =================================================================
def main():
    print("Connecting to PostgreSQL...")
    conn = psycopg2.connect(**DB_CONFIG)

    truncate_all_tables(conn) 

    # Order matters due to FK dependencies
    LOAD_ORDER = [
        ("issuers", "issuers.csv"),
        ("bond_purposes", "bond_purposes.csv"),
        ("bonds", "bonds.csv"),
        ("credit_ratings", "credit_ratings.csv"),
        ("trades", "trades.csv"),
        ("economic_indicators", "economic_indicators.csv"),
    ]

    # Load data in FK-safe order
    for table, file in LOAD_ORDER:
        load_csv(conn, table, file)

    # Summary
    print_row_counts(conn, [t for t, _ in LOAD_ORDER])

    # FK Validation
    print("\n=== Referential Integrity Checks ===")
    check_fk(conn, "bonds", "issuer_id", "issuers", "issuer_id")
    check_fk(conn, "bonds", "purpose_id", "bond_purposes", "purpose_id")
    check_fk(conn, "credit_ratings", "bond_id", "bonds", "bond_id")
    check_fk(conn, "trades", "bond_id", "bonds", "bond_id")

    print("\n=== DONE ===")
    conn.close()


if __name__ == "__main__":
    main()
