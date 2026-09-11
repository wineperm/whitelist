#!/bin/bash
set -e

OUTPUT_LST="russia-mobile-whitelist.lst"
OUTPUT_SRS="russia-mobile-whitelist.srs"
TEMP_JSON="rules.json"
SOURCE_URL="https://raw.githubusercontent.com/hxehex/russia-mobile-internet-whitelist/main/whitelist.txt"

echo "📥 Скачивание исходного списка..."
curl -sL "$SOURCE_URL" -o temp_whitelist.txt

echo "🧹 Очистка списка..."
# Удаляем BOM, пустые строки, пробелы по краям и комментарии
sed -i '1s/^\xEF\xBB\xBF//' temp_whitelist.txt 2>/dev/null || true
sed -i '/^$/d' temp_whitelist.txt
sed -i 's/^[ \t]*//; s/[ \t]*$//' temp_whitelist.txt
sed -i '/^#/d' temp_whitelist.txt

# Проверка на пустоту
if [ ! -s temp_whitelist.txt ]; then
  echo "❌ Ошибка: список пуст после очистки"
  exit 1
fi

# Сохраняем очищенный список
mv temp_whitelist.txt "$OUTPUT_LST"
echo "✅ Очищенный список сохранен в $OUTPUT_LST"

echo "🛠 Формирование JSON для sing-box (версия 3)..."
echo '{"version": 3, "rules": [{"domain_suffix": [' > "$TEMP_JSON"
sed 's/^/"/; s/$/"/' "$OUTPUT_LST" | paste -sd ',' >> "$TEMP_JSON"
echo ']}]}' >> "$TEMP_JSON"

echo "⚙️ Компиляция в формат .srs через Docker..."
docker run --rm -v "${GITHUB_WORKSPACE:-$(pwd)}:/data" ghcr.io/sagernet/sing-box:latest \
  rule-set compile --output "/data/$OUTPUT_SRS" "/data/$TEMP_JSON"

if [ -f "$OUTPUT_SRS" ]; then
  echo "✅ SRS файл успешно создан: $OUTPUT_SRS"
  ls -la "$OUTPUT_SRS"
else
  echo "❌ Ошибка: SRS файл не был создан"
  exit 1
fi

# Удаляем временный JSON
rm -f "$TEMP_JSON"
