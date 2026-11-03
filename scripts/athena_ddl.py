#!/usr/bin/env python3
"""Create or update Iceberg tables in Athena from data-contracts/*-data-contract.json.

Usage: python3 scripts/athena_ddl.py <database> <bucket> <workgroup> [--dry-run]
"""
import glob
import json
import sys
import time

import boto3

# --- Inputs (passed in by the GHA workflow) ---
database = sys.argv[1]                # e.g. lf_learn_dev
bucket = sys.argv[2]                  # e.g. lf-learn-iceberg-storage-dev-<account_id>
workgroup = sys.argv[3]               # e.g. lf-learn-dev
dry_run = "--dry-run" in sys.argv     # print SQL only, don't run it

athena = boto3.client("athena")
glue = boto3.client("glue")


def run(sql):
    """Send one SQL statement to Athena and wait until it finishes."""
    print(sql + ";\n")
    if dry_run:
        return

    query_id = athena.start_query_execution(
        QueryString=sql,
        WorkGroup=workgroup,  # the workgroup decides where results are written
    )["QueryExecutionId"]

    # Athena runs queries in the background, so poll until it's done
    while True:
        status = athena.get_query_execution(QueryExecutionId=query_id)["QueryExecution"]["Status"]
        if status["State"] not in ("QUEUED", "RUNNING"):
            break
        time.sleep(1)

    if status["State"] != "SUCCEEDED":
        sys.exit(f"Athena failed: {status.get('StateChangeReason')}")


def column_sql(col):
    """Turn one contract column into the SQL Athena needs, e.g.
    {"name": "order_id", "type": "string", "description": "Order ID"}
    -> `order_id` string COMMENT 'Order ID'
    """
    # A ' inside the text would end the SQL string early ("buyer's note"), so double it: ''
    description = (col.get("description") or "").replace("'", "''")
    return f"`{col['name']}` {col['type']} COMMENT '{description}'"


def partition_sql(columns):
    """Build the PARTITIONED BY line from columns that have a "partition" value, e.g.
    {"name": "order_timestamp", "partition": "day"} -> PARTITIONED BY (day(`order_timestamp`))
    {"name": "country", "partition": "identity"}    -> PARTITIONED BY (`country`)
    No partitioned columns -> "" (table is not partitioned)
    """
    partitions = []
    for c in columns:
        if not c.get("partition"):
            continue
        if c["partition"] == "identity":
            partitions.append(f"`{c['name']}`")
        else:
            partitions.append(f"{c['partition']}(`{c['name']}`)")

    if not partitions:
        return ""
    return f"PARTITIONED BY ({', '.join(partitions)})\n"


# --- One loop per data contract file ---
# Contracts live in this git repo (data-contracts/), not in AWS.
# In GHA, actions/checkout downloads the repo onto the runner, so the files are read from there.
for path in glob.glob("data-contracts/*-data-contract.json"):
    contract = json.load(open(path))
    table = f"`{database}`.`{contract['tablename']}`"
    columns = contract["columns"]

    # 1. Ask Glue: does the table exist? If yes, which columns does it have?
    try:
        glue_table = glue.get_table(DatabaseName=database, Name=contract["tablename"])["Table"]
        existing = {c["Name"]: c["Type"] for c in glue_table["StorageDescriptor"]["Columns"]}
    except glue.exceptions.EntityNotFoundException:
        existing = None

    # 2. Table doesn't exist -> CREATE it
    if existing is None:
        column_list = ",\n  ".join(column_sql(c) for c in columns)

        run(
            f"CREATE TABLE {table} (\n  {column_list}\n)\n"
            f"{partition_sql(columns)}"
            f"LOCATION 's3://{bucket}/{contract['dataset']}/{contract['tablename']}/'\n"
            "TBLPROPERTIES ('table_type'='ICEBERG')"
        )
        continue

    # 3. Table exists -> make its columns match the contract
    wanted = {c["name"]: c for c in columns}

    for name, col in wanted.items():
        if name not in existing:                      # new in contract -> add
            run(f"ALTER TABLE {table} ADD COLUMNS ({column_sql(col)})")
        elif existing[name] != col["type"]:           # type changed -> change
            run(f"ALTER TABLE {table} CHANGE COLUMN `{name}` {column_sql(col)}")

    for name in existing:
        if name not in wanted:                        # removed from contract -> drop
            run(f"ALTER TABLE {table} DROP COLUMN `{name}`")
