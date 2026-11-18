Только тесты заглушек. Из корня распакованного архива на Linux с liblua-5.3 и Python 3:
mkdir -p SOURCE/TESTS/tmp
python3 SOURCE/TESTS/run_lua_file.py INSTALL/payload/*.script SOURCE/TESTS/test_sidecar.lua
python3 SOURCE/TESTS/run_lua_file.py SOURCE/TESTS/test_integration.lua
python3 SOURCE/TESTS/test_package.py
rm -rf SOURCE/TESTS/tmp
Рабочий каталог тестовых файлов SOURCE/TESTS/tmp; реальные файлы игры и сейвы не затрагиваются. В Windows PowerShell и игре не тестировалось.
