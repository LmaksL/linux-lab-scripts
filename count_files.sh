#!/bin/bash
# Универсальный скрипт для Лаб №2:
# - подсчет обычных файлов
# - расширенная статистика (файлы/директории/ссылки)
# - фильтр по расширению
# - параметр директории
# - рекурсивный подсчет
# - общий размер найденных файлов

usage() {
  echo "Использование: $0 [-d DIR] [-e EXT] [-r] [-a] [-s]"
  echo "  -d DIR  директория (по умолчанию /etc)"
  echo "  -e EXT  считать только файлы с расширением (пример: conf или .conf)"
  echo "  -r      рекурсивно (включая поддиректории)"
  echo "  -a      показать расширенную статистику (files/dirs/links)"
  echo "  -s      посчитать общий размер найденных файлов"
  echo ""
  echo "Примеры:"
  echo "  $0"
  echo "  $0 -d /etc"
  echo "  $0 -d /etc -e conf"
  echo "  $0 -d /etc -r"
  echo "  $0 -d /etc -r -s"
  echo "  $0 -d /etc -a"
}

# значения по умолчанию
TARGET_DIR="/etc"
EXT_FILTER=""
RECURSIVE=0
SHOW_ALL=0
SHOW_SIZE=0

# парсим аргументы
while getopts ":d:e:ras h" opt; do
  case "$opt" in
    d) TARGET_DIR="$OPTARG" ;;
    e) EXT_FILTER="$OPTARG" ;;
    r) RECURSIVE=1 ;;
    a) SHOW_ALL=1 ;;
    s) SHOW_SIZE=1 ;;
    h) usage; exit 0 ;;
    \?) echo "Ошибка: неизвестный параметр -$OPTARG"; usage; exit 1 ;;
    :)  echo "Ошибка: параметр -$OPTARG требует значение"; usage; exit 1 ;;
  esac
done

# нормализуем расширение
if [ -n "$EXT_FILTER" ]; then
  EXT_FILTER="${EXT_FILTER#.}"   # убираем точку, если пользователь ввел ".conf"
fi

# проверка директории
if [ ! -d "$TARGET_DIR" ]; then
  echo "Помилка: директорія $TARGET_DIR не існує"
  exit 1
fi

# формируем параметры find
MAXDEPTH_ARGS=()
if [ "$RECURSIVE" -eq 0 ]; then
  MAXDEPTH_ARGS=(-maxdepth 1)
fi

NAME_ARGS=()
if [ -n "$EXT_FILTER" ]; then
  NAME_ARGS=(-name "*.${EXT_FILTER}")
fi

# считаем файлы
files_count=$(find "$TARGET_DIR" "${MAXDEPTH_ARGS[@]}" -type f "${NAME_ARGS[@]}" 2>/dev/null | wc -l)

echo "======================================"
echo "Статистика для: $TARGET_DIR"
echo "Режим: $([ "$RECURSIVE" -eq 1 ] && echo 'рекурсивный' || echo 'только текущая директория')"
if [ -n "$EXT_FILTER" ]; then
  echo "Фильтр расширения: .$EXT_FILTER"
else
  echo "Фильтр расширения: (нет)"
fi
echo "======================================"
echo ""
echo "Кількість звичайних файлів: $files_count"
echo "Run time: $(date)"


# расширенная статистика (директории и ссылки) — без учета расширения, как в методичке
if [ "$SHOW_ALL" -eq 1 ]; then
  dirs_count=$(find "$TARGET_DIR" "${MAXDEPTH_ARGS[@]}" -type d 2>/dev/null | wc -l)
  links_count=$(find "$TARGET_DIR" "${MAXDEPTH_ARGS[@]}" -type l 2>/dev/null | wc -l)

  # если не рекурсивно — вычтем саму директорию
  if [ "$RECURSIVE" -eq 0 ]; then
    dirs_count=$((dirs_count - 1))
  fi

  echo ""
  echo "Директорії: $dirs_count"
  echo "Символічні посилання: $links_count"
fi

# общий размер найденных файлов
if [ "$SHOW_SIZE" -eq 1 ]; then
  # Вариант через stat (обычно работает в Linux/WSL/Git Bash)
  total_bytes=$(find "$TARGET_DIR" "${MAXDEPTH_ARGS[@]}" -type f "${NAME_ARGS[@]}" -print0 2>/dev/null \
    | xargs -0 stat -c %s 2>/dev/null \
    | awk '{s+=$1} END{print s+0}')

  echo ""
  echo "Загальний розмір знайдених файлів (байт): $total_bytes"

  # если есть numfmt — красиво выведем
  if command -v numfmt >/dev/null 2>&1; then
    echo "Загальний розмір (людський формат): $(numfmt --to=iec --suffix=B $total_bytes)"
  fi
fi

echo ""
echo "(Директорії та символічні посилання не враховані у підрахунку файлів)"
exit 0
