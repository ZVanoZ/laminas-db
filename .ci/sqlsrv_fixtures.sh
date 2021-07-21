#!/usr/bin/env bash

echo "Configure MSSQL server test database"

sqlcmd -S localhost -U sa -P Password123 -Q "DROP DATABASE IF EXISTS laminasdb_test;"
sqlcmd -S localhost -U sa -P Password123 -Q "CREATE DATABASE laminasdb_test;"
