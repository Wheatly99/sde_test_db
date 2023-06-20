#!/bin/bash

docker pull postgres

docker run --name post -e POSTGRES_PASSWORD="@sde_password012" \
 -e POSTGRES_USER="test_sde" \
 -e POSTGRES_DB="demo" \
 -p 127.0.0.1:5432:5432 \
 -v /$(pwd)/../sql:/sql \
 -d postgres

sleep 2s

docker exec -it "post" psql -d "demo" -U "test_sde" -f ./sql/init_db/demo.sql