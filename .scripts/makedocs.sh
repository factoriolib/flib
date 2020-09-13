
echo "Auto Generating with ldoc"
rm -rf "flib-docs"
mkdir -p "flib-docs"
cp docs/css/spectre.min.css "flib-docs/spectre.min.css"
cp docs/css/spectre-icons.min.css "flib-docs/spectre-icons.min.css"
ldoc -ic docs/ldoc-config.ld ./
