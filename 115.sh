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
    echo "0: 退出"
}

# 定义一个全局变量来存储生成的目录文件路径
generated_directory_file=""

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

exclude_option = $exclude_option
alist_url = "$alist_url"
strm_save_path = "$strm_save_path"
generated_directory_file = "$generated_directory_file"

# 获取文件行数
with open(generated_directory_file, 'r', encoding='utf-8') as f:
    total_lines = sum(1 for _ in f)

processed_lines = 0
lock = threading.Lock()

def process_line(line):
    global processed_lines
    line = line.rstrip()
    line_depth = line.count('/')
    
    if line_depth < exclude_option:
        return
    
    adjusted_path = '/'.join(line.split('/')[exclude_option+1:])
    
    if not adjusted_path:
        return
    
    file_extension = line.split('.')[-1].lower()
    
    if file_extension in media_extensions:
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
        print(f"\r总文件：{total_lines}，已处理：{processed_lines}，进度：{processed_lines / total_lines:.2%}", end='')

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
        0)
            echo "退出程序。"
            break
            ;;
        *)
            echo "无效的选项，请输入 0、1 或 2。"
            ;;
    esac
done
