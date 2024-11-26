#!/bin/bash

# 设置 UTF-8 环境
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# 检查是否安装了 Python 3
if ! command -v python3 &> /dev/null; then
    echo "Python 3 未安装，请安装后再运行此脚本。"
    exit 1
fi

# 菜单函数
show_menu() {
    echo "请选择操作："
    echo "1: 将目录树转换为目录文件"
    echo "2: 生成 .strm 文件"
    echo "3: 建立alist索引数据库"
    echo "4: 高级配置（处理非常见媒体文件时使用）"
    echo "0: 退出"
}

# 定义一个全局变量来存储生成的目录文件路径
generated_directory_file=""
custom_extensions=""

# 内置的媒体文件扩展名
builtin_audio_extensions=("mp3" "flac" "wav" "aac" "ogg" "wma" "alac" "m4a" "aiff" "ape" "dsf" "dff" "wv" "pcm" "tta")
builtin_video_extensions=("mp4" "mkv" "avi" "mov" "wmv" "flv" "webm" "vob" "mpg" "mpeg")
builtin_image_extensions=("jpg" "jpeg" "png" "gif" "bmp" "tiff" "svg" "heic")
builtin_other_extensions=("iso" "img" "bin" "nrg" "cue" "dvd" "lrc" "srt" "sub" "ssa" "ass" "vtt" "txt" "pdf" "doc" "docx" "csv" "xml" "new")

# 目录树转换函数
convert_directory_tree() {
    echo "请输入目录树文件的路径，例如：/path/to/alist20250101000000_目录树.txt"
    read -r directory_tree_file

    if [ ! -f "$directory_tree_file" ]; then
        echo "目录树文件不存在，请提供有效的文件路径。"
        return
    fi

    # 获取目录树文件的目录和文件名
    directory_tree_dir=$(dirname "$directory_tree_file")
    directory_tree_base=$(basename "$directory_tree_file")

    # 转换目录树文件为 UTF-8 格式（如有需要）
    converted_file="$directory_tree_dir/$directory_tree_base.converted"
    iconv -f utf-16le -t utf-8 "$directory_tree_file" -o "$converted_file"

    # 生成的目录文件路径
    generated_directory_file="${converted_file}_目录文件.txt"

    # 使用 Python 进行目录树解析
    python3 - <<EOF
import os

def parse_directory_tree(file_path):
    current_path_stack = []
    directory_list_file = "${generated_directory_file}"

    with open(file_path, 'r', encoding='utf-8') as file, \
         open(directory_list_file, 'w', encoding='utf-8') as output_file:
        for line in file:
            line = line.lstrip('\ufeff').rstrip()
            line_depth = line.count('|')
            item_name = line.split('|-')[-1].strip()
            if not item_name:
                continue
            while len(current_path_stack) > line_depth:
                current_path_stack.pop()
            if len(current_path_stack) == line_depth:
                if current_path_stack:
                    current_path_stack.pop()
            current_path_stack.append(item_name)
            full_path = '/' + '/'.join(current_path_stack)
            output_file.write(full_path + '\n')

parse_directory_tree("$converted_file")
EOF

    # 清理临时文件
    rm "$converted_file"
    echo "目录文件已生成：$generated_directory_file"
}

# 自动选择可能的目录文件
find_possible_directory_file() {
    # 扫描当前目录中以 "_目录文件.txt" 结尾的文件
    possible_files=($(ls *_目录文件.txt 2> /dev/null | sort -V))

    if [ ${#possible_files[@]} -eq 0 ]; then
        echo "没有找到符合条件的目录文件。"
        return 1
    fi

    echo "找到以下目录文件，请选择："
    select file in "${possible_files[@]}" "输入完整路径"; do
        case $file in
            "输入完整路径")
                echo "请输入目录文件的完整路径："
                read -r generated_directory_file
                if [ ! -f "$generated_directory_file" ]; then
                    echo "文件不存在，请重新输入。"
                    return 1
                fi
                break
                ;;
            *)
                generated_directory_file=$file
                break
                ;;
        esac
    done
}

# 生成 .strm 文件的函数
generate_strm_files() {
    if [ -z "$generated_directory_file" ]; then
        if ! find_possible_directory_file; then
            return
        fi
    fi

    # 提示用户输入用于保存 .strm 文件的路径
    echo "请输入 .strm 文件保存的路径："
    read -r strm_save_path
    mkdir -p "$strm_save_path"

    # 提示用户输入剔除选项
    echo "请输入剔除选项（输入要剔除的目录层级数量）："
    read -r exclude_option

    # 确保 exclude_option 是一个非负整数
    if ! [[ "$exclude_option" =~ ^[0-9]+$ ]]; then
        echo "无效的选项，请输入一个非负整数。"
        return
    fi

    # 提示用户输入URL前缀
    echo "请输入alist的地址+端口（例如：http://abc.com:5244）："
    read -r alist_url
    # 确保URL的格式正确，以 / 结尾
    if [[ "$alist_url" != */ ]]; then
        alist_url="$alist_url/"
    fi
    alist_url="${alist_url}d/"
    
    # 使用 Python 生成 .strm 文件并处理多线程与进度显示
    python3 - <<EOF
import os
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
import urllib.parse
import threading

# 定义常见的媒体文件扩展名
media_extensions = set([
    "mp3", "flac", "wav", "aac", "ogg", "wma", "alac", "m4a",
    "aiff", "ape", "dsf", "dff", "wv", "pcm", "tta",
    "mp4", "mkv", "avi", "mov", "wmv", "flv", "webm", "vob", "mpg", "mpeg",
    "jpg", "jpeg", "png", "gif", "bmp", "tiff", "svg", "heic",
    "iso", "img", "bin", "nrg", "cue", "dvd",
    "lrc", "srt", "sub", "ssa", "ass", "vtt", "txt",
    "pdf", "doc", "docx", "csv", "xml", "new"
])

# 合并用户自定义扩展名
custom_extensions = set("${custom_extensions}".split())
media_extensions.update(custom_extensions)

exclude_option = $exclude_option
alist_url = "$alist_url"
strm_save_path = "$strm_save_path"
generated_directory_file = "$generated_directory_file"

# 获取文件行数
with open(generated_directory_file, 'r', encoding='utf-8') as f:
    total_lines = sum(1 for _ in f)

processed_lines = 0
lock = threading.Lock()
start_time = time.time()

def process_line(line):
    global processed_lines
    line = line.rstrip()
    line_depth = line.count('/')

    if line_depth < exclude_option:
        return

    adjusted_path = '/'.join(line.split('/')[exclude_option+1:])

    if not adjusted_path:
        return

    file_extension = adjusted_path.split('.')[-1].lower()
    
    # 判断是文件还是目录
    is_dir = 0 if file_extension in media_extensions else 1

    if is_dir == 0:
        file_name = os.path.basename(adjusted_path)
        parent_path = os.path.dirname(adjusted_path)
        
        os.makedirs(os.path.join(strm_save_path, parent_path), exist_ok=True)
        
        encoded_path = urllib.parse.quote(f"{parent_path}/{file_name}")
        # 修改点：包括完整文件名（含扩展名）用于 .strm 文件的命名
        strm_file_path = os.path.join(strm_save_path, parent_path, f"{file_name}.strm")
        
        with open(strm_file_path, 'w', encoding='utf-8') as strm_file:
            strm_file.write(f"{alist_url}{encoded_path}")
    
    with lock:
        processed_lines += 1
        elapsed_time = time.time() - start_time
        minutes, seconds = divmod(int(elapsed_time), 60)
        print(f"\r总文件：{total_lines}，已处理：{processed_lines}，进度：{processed_lines / total_lines:.2%}，耗时：{minutes:02}:{seconds:02}", end='')

with open(generated_directory_file, 'r', encoding='utf-8') as file:
    lines = file.readlines()

# 根据机器性能合理设置线程池大小
max_workers = min(4, os.cpu_count() or 1)

with ThreadPoolExecutor(max_workers=max_workers) as executor:
    futures = [executor.submit(process_line, line) for line in lines]
    for _ in as_completed(futures):
        pass

print("\n已完成 .strm 文件生成。")
EOF
}

# 建立 alist 索引数据库的函数
build_index_database() {
    if [ -z "$generated_directory_file" ]; then
        if ! find_possible_directory_file; then
            return
        fi
    fi

    echo "建议数据库备份后操作，请选择数据库文件:"
    select db_file in *.db "输入完整路径"; do
        case $db_file in
            "输入完整路径")
                echo "请输入数据库文件的完整路径："
                read -r db_file
                if [ ! -f "$db_file" ]; then
                    echo "文件不存在，请重新输入。"
                    return
                fi
                break
                ;;
            *.db)
                break
                ;;
            *)
                echo "无效选择，请重试。"
                ;;
        esac
    done

    echo "请输入剔除选项（输入要剔除的目录层级数量）："
    read -r exclude_option

    if ! [[ "$exclude_option" =~ ^[0-9]+$ ]]; then
        echo "无效的选项，请输入一个非负整数。"
        return
    fi

    temp_db_file=$(mktemp --suffix=.db)
    
    python3 - <<EOF
import sqlite3
import os
import time

exclude_option = $exclude_option
generated_directory_file = "$generated_directory_file"
temp_db_file = "$temp_db_file"

def is_directory(name):
    # 判断路径是否为文件夹
    return '.' not in name

def insert_data_into_temp_db(file_path, db_path, exclude_level):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    cursor.execute('''
    CREATE TABLE IF NOT EXISTS x_search_nodes (
        parent TEXT,
        name TEXT,
        is_dir INTEGER,
        size INTEGER
    )
    ''')

    with open(file_path, 'r', encoding='utf-8') as file:
        total_lines = sum(1 for _ in file)
        file.seek(0)  # 重置文件指针
        processed_lines = 0
        start_time = time.time()

        for line in file:
            line = line.rstrip()
            path_parts = line.split('/')[exclude_level+1:]

            if len(path_parts) < 1:
                continue

            parent = '/' + '/'.join(path_parts[:-1])
            name = path_parts[-1]
            
            # 更新 is_dir 判断逻辑
            is_dir = 0 if is_directory(name) else 1

            cursor.execute('INSERT INTO x_search_nodes (parent, name, is_dir, size) VALUES (?, ?, ?, 0)', (parent, name, is_dir))
            
            processed_lines += 1
            elapsed_time = time.time() - start_time
            minutes, seconds = divmod(int(elapsed_time), 60)
            print(f"\r总文件：{total_lines}，已处理：{processed_lines}，进度：{processed_lines / total_lines:.2%}，耗时：{minutes:02}:{seconds:02}", end='')

    print()  # 换行
    conn.commit()
    conn.close()

insert_data_into_temp_db(generated_directory_file, temp_db_file, exclude_option)
EOF

    echo "数据已处理完毕。请选择操作："
    echo "1: 新增到现有数据库索引表，如果你数据库已经有索引信息，选择1"
    echo "2: 替换现有数据库索引表，如果你数据库已经没有索引信息，选择2"

    read -r db_choice

    # 根据选择执行相应操作
    case $db_choice in
        1)
            # 新增数据到数据库
            sqlite3 "$db_file" <<SQL
ATTACH DATABASE '$temp_db_file' AS tempdb;
INSERT INTO main.x_search_nodes (parent, name, is_dir, size)
SELECT parent, name, is_dir, size FROM tempdb.x_search_nodes;
DETACH DATABASE tempdb;
SQL
            ;;
        2)
            # 替换数据库表数据
            sqlite3 "$db_file" <<SQL
DELETE FROM x_search_nodes;
ATTACH DATABASE '$temp_db_file' AS tempdb;
INSERT INTO main.x_search_nodes (parent, name, is_dir, size)
SELECT parent, name, is_dir, size FROM tempdb.x_search_nodes;
DETACH DATABASE tempdb;
SQL
            ;;
        *)
            echo "无效的选项，操作已取消。"
            rm "$temp_db_file"
            return
            ;;
    esac

    # 在数据库中创建索引
    sqlite3 "$db_file" <<SQL
CREATE INDEX IF NOT EXISTS idx_x_search_nodes_parent ON x_search_nodes (parent);
SQL

    # 删除临时数据库文件
    rm "$temp_db_file"
    echo "操作完成，索引已更新。"
}

# 打印内置格式的函数
print_builtin_formats() {
    echo "内置的媒体文件格式如下："
    echo "音频格式: ${builtin_audio_extensions[*]// /、}"
    echo "视频格式: ${builtin_video_extensions[*]// /、}"
    echo "图片格式: ${builtin_image_extensions[*]// /、}"
    echo "其他格式: ${builtin_other_extensions[*]// /、}"
}

# 高级配置函数
advanced_configuration() {
    echo "由于115目录树没有对文件和文件夹进行定义，本脚本内置了常用文件格式进行文件和文件夹的判断。"
    echo "如果你处理的文件格式不常见，你可以在这里添加，多个格式请使用空格分隔，不需要一个个对，脚本自动会去重，例如：mp3 mp4"，
    echo "退回主菜单请输入0，打印脚本内置格式请输入1。"
    read -r user_input

    if [[ "$user_input" == "0" ]]; then
        return
    elif [[ "$user_input" == "1" ]]; then
        print_builtin_formats
        return
    fi

    # 转换为小写并去重
    new_extensions=$(echo "$user_input" | tr ' ' '\n' | tr '[:upper:]' '[:lower:]' | sort -u)
    
    # 更新全局变量
    for ext in $new_extensions; do
        if ! echo "$custom_extensions" | grep -qw "$ext"; then
            custom_extensions="$custom_extensions $ext"
        fi
    done

    echo "已添加的自定义扩展名：$custom_extensions"
}

# 主循环
while true; do
    show_menu
    read -r choice
    case $choice in
        1)
            convert_directory_tree
            ;;
        2)
            generate_strm_files
            ;;
        3)
            build_index_database
            ;;
        4)
            advanced_configuration
            ;;
        0)
            echo "退出程序。"
            break
            ;;
        *)
            echo "无效的选项，请输入 0、1、2、3 或 4。"
            ;;
    esac
done
