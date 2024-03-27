#!/usr/bin/env bash
set -e

# переносим значения переменных из текущего окружения
env | while read -r LINE; do  # читаем результат команды 'env' построчно
    # делим строку на две части, используя в качестве разделителя "=" (см. IFS)
    IFS="=" read VAR VAL <<< ${LINE}
    # удаляем все предыдущие упоминания о переменной, игнорируя код возврата
    sed --in-place "/^${VAR}/d" /etc/security/pam_env.conf || true
    # добавляем определение новой переменной в конец файла
    echo "${VAR} DEFAULT=\"${VAL}\"" >> /etc/security/pam_env.conf
done

if [[ (-n ${MINIO_ENDPOINT_URL}) && (-n ${MINIO_ACCESS_KEY_ID}) && (-n ${MINIO_SECRET_ACCESS_KEY}) && (-n ${MINIO_BUCKET}) ]]; then
mc config --quiet host add minio ${MINIO_ENDPOINT_URL} ${MINIO_ACCESS_KEY_ID} ${MINIO_SECRET_ACCESS_KEY} 2>&1 1>/dev/null
fi

exec "$@"
