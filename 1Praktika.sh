#!/bin/bash

# Функция для вывода списка пользователей
list_users() {
    cut -d: -f1,6 /etc/passwd | sort | cat
}

# Функция для вывода списка процессов
list_processes() {
    ps -eo pid,comm --sort pid
}

# Функция для вывода справки
show_help() {
    echo "Использование: $0 [опции]"
    echo ""
    echo "Опции:"
    echo "  -u, --users              Вывести список пользователей и их домашних директорий."
    echo "  -p, --processes          Вывести список запущенных процессов."
    echo "  -h, --help               Показать справку."
    echo "  -l PATH, --log PATH      Записать вывод в файл по заданному пути PATH."
    echo "  -e PATH, --errors PATH   Записать вывод ошибок в файл по заданному пути PATH."
}

# Переменные для обработки вывода
log_file="/home/oleg/complete.log"
error_file="/home/oleg/error.log"
exec 3>&1 4>&2

# Обработка аргументов командной строки
while getopts ":upl:he:-:" opt; do
    case $opt in
        u)
            output=$(list_users 2>&1) || error_output=$?
            ;;
        p)
            output=$(list_processes 2>&1) || error_output=$?
            ;;
        l)
            log_file="$OPTARG"
            ;;
        e)
            error_file="$OPTARG"
            ;;
        h)
            show_help
            exit 0
            ;;
        -)
            case "${OPTARG}" in
                users)
                    output=$(list_users 2>&1) || error_output=$?
                    ;;
                processes)
                    output=$(list_processes 2>&1) || error_output=$?
                    ;;
                help)
                    show_help
                    exit 0
                    ;;
                log)
                    log_file="${!OPTIND}"; OPTIND=$(( OPTIND + 1 ))
                    ;;
                errors)
                    error_file="${!OPTIND}"; OPTIND=$(( OPTIND + 1 ))
                    ;;
                *)
                    echo "Неверный аргумент: --${OPTARG}" >&2
                    exit 1
                    ;;
            esac
            ;;
        \?)
            echo "Недопустимый параметр: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Опция -$OPTARG требует аргумента." >&2
            exit 1
            ;;
    esac
done

# Направление вывода в файл, если указано
if [[ -n "$log_file" ]]; then
    if [[ -w $(dirname "$log_file") ]]; then
        exec > >(tee -a "$log_file")
    else
        echo "Ошибка: нет доступа к пути $log_file для записи." >&2
        exit 1
    fi
fi

# Направление вывода ошибок в файл, если указано
if [[ -n "$error_file" ]]; then
    if [[ -w $(dirname "$error_file") ]]; then
        exec 2>"$error_file"
    else
        echo "Ошибка: нет доступа к пути $error_file для записи." >&2
        exit 1
    fi
fi

# Вывод результата
if [[ -n "$output" ]]; then
    echo "$output"
else
    echo "Не указаны параметры для выполнения." >&2
    exit 1
fi
