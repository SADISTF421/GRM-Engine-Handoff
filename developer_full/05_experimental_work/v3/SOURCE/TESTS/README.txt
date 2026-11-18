Команда из корня распакованного архива: python3 SOURCE/TESTS/run_lua_file.py INSTALL/payload/grm_gore_test.script INSTALL/payload/xr_motivator.script SOURCE/TESTS/test_runtime.lua
Нужны Python 3 и liblua-5.3. Создаётся тестовая Lua VM с заглушками; реальные механизмы и сериализация не исполняются. Дополнительная проверка python3 SOURCE/TESTS/test_package.py. На Windows PowerShell тестов не было.
