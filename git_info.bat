@echo off
setlocal enabledelayedexpansion

:: 1. 捕获 stdin 到临时文件
set "tmpfile=%temp%\info_%random%.json"
more > "%tmpfile%"

if not exist "%tmpfile%" exit /b 1

:: 2. 提取基础字段
for /f "usebackq delims=" %%i in (`jq -r ".model.display_name" "%tmpfile%"`) do set "model=%%i"
for /f "usebackq delims=" %%i in (`jq -r ".workspace.current_dir" "%tmpfile%"`) do set "workspace=%%i"

:: 3. 提取 Workspace 的最后一级目录名 (模拟 basename)
for %%F in ("%workspace%") do set "dir_name=%%~nxF"

:: 4. 提取 Metrics Tokens
:: 注意：jq 中访问动态键需要使用 ["key"] 语法
set "jq_path_tokens=.metrics.models[\"%model%\"].tokens"

for /f "usebackq delims=" %%i in (`jq -r "%jq_path_tokens%.total" "%tmpfile%"`) do set "tok_total=%%i"
for /f "usebackq delims=" %%i in (`jq -r "%jq_path_tokens%.prompt" "%tmpfile%"`) do set "tok_prompt=%%i"
for /f "usebackq delims=" %%i in (`jq -r "%jq_path_tokens%.completion" "%tmpfile%"`) do set "tok_comp=%%i"
for /f "usebackq delims=" %%i in (`jq -r "%jq_path_tokens%.cached" "%tmpfile%"`) do set "tok_cached=%%i"
for /f "usebackq delims=" %%i in (`jq -r "%jq_path_tokens%.thoughts" "%tmpfile%"`) do set "tok_thoughts=%%i"


:: 5. 提取 Context Window 中的 total_input_tokens 和 total_output_tokens
for /f "usebackq delims=" %%i in (`jq -r ".context_window.total_input_tokens" "%tmpfile%"`) do set "total_input=%%i"
for /f "usebackq delims=" %%i in (`jq -r ".context_window.total_output_tokens" "%tmpfile%"`) do set "total_output=%%i"

:: 6. 清理
del "%tmpfile%" >nul 2>&1

:: 7. 输出 (两行)
echo Model: %model% ^| Dir: %workspace%
echo Tokens: %tok_total% ^| Input: %tok_prompt% ^| Output: %tok_comp% ^| Cache: %tok_cached% ^| Thoughts: %tok_thoughts%

endlocal