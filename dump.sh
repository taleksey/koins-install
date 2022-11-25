#!/bin/bash

if test "$BASH" = ""; then
  echo "You must use: bash $0"
  exit 1
fi

MYSQL_USER="%mysql_user%"
MYSQL_PASS="%mysql_password%"
BACKUP_DIR="%workspace%/backup/$(date +%Y-%m-%d_%H_%M_%S)"

tmp_dir=$(mktemp -d -t ci-XXXXXXXXXX)

# Get the database list, exclude information_schema
for db in $(mysql -B -s -u ${MYSQL_USER} --password=${MYSQL_PASS} -e 'show databases' | grep -v information_schema)
do
  if [[ "${db}" == *"test"* ]] || [[ "${db}" == "a_geo" ]] || [[ "${db}" == "mysql" ]] || [[ "${db}" == "information_schema" ]] || [[ "${db}" == "performance_schema" ]] || [[ "${db}" == "sys" ]] || [[ "${db}" == *"control"* ]]; then
      echo "Ignore database: ${db}"
  else
    echo "Dumping database: ${db}"
    # dump each database in a separate file
    mysqldump -u ${MYSQL_USER} --password=${MYSQL_PASS} --no-tablespaces --ignore-table=${db}.core_log_cache --ignore-table=${db}.core_search_provider_index --ignore-table=${db}.core_amazon_search_index --ignore-table=${db}.core_sos_provider_database --skip-triggers "$db" > "$tmp_dir/$db.sql"
  fi
done

test -d "$BACKUP_DIR" || mkdir -p "$BACKUP_DIR"
cp -r ${tmp_dir}/* "${BACKUP_DIR}"
rm -rf ${tmp_dir}

echo "Dumping database complete"
echo "Dump save to ${BACKUP_DIR}"
