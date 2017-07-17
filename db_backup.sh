#!/bin/bash

date=$(date +'%Y-%m-%d-%H-%M-%S')
filename="dump-${date}.tar.gz"

echo "Backking up database to ${filename}, please wait..."

pg_dump -h localhost --username lodgistics --format c --no-owner --verbose --file "${filename}" lodgistics_production