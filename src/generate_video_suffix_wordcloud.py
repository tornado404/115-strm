from pathlib import Path
from collections import Counter
from wordcloud import WordCloud
from loguru import logger
import matplotlib.pyplot as plt
import chardet  # 用于检测文件编码
import os
VIDEO_SUFFIXES = {'.mp4', '.avi', '.mov', '.mkv'}  # 示例视频后缀集合

def detect_file_encoding(file_path):
    with open(file_path, 'rb') as f:
        raw_data = f.read()
    result = chardet.detect(raw_data)
    return result['encoding']

def extract_video_names(file_path) -> Counter:
    """
    从目录树.txt中提取所有视频文件的名称（去除空格和后缀），并统计频率
    """
    name_counter = Counter()

    if not os.path.exists(file_path):
        print(f"文件不存在：{file_path}")
        return name_counter

    try:
        encoding = detect_file_encoding(file_path)
        print(f"检测到目录树文件编码: {encoding}")
        blacklist = read_blacklist("./blacklist.txt")
        with open(file_path, 'r', encoding=encoding) as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue

                try:
                    path = Path(line)
                    if path.suffix.lower() in VIDEO_SUFFIXES:
                        # 获取不含路径和后缀的文件名，去掉空格
                        clean_name = path.stem.replace(' ', '').replace('|-', '').replace('|', '')
                        
                        if any(keyword in clean_name.lower() for keyword in blacklist):
                            print(f"已过滤视频：{clean_name} 命中黑名单")
                            continue
                        name_counter[clean_name] += 1
                except (OSError, ValueError) as e:
                    print(f"无效路径格式：{line} ({str(e)})")

    except UnicodeDecodeError as e:
        print(f"尝试使用其他编码重新读取文件 {e}")

    print(f"共提取到 {sum(name_counter.values())} 个视频名称")
    return name_counter

def read_blacklist(blacklist_path: str) -> set:
    """
    从黑名单文件中读取黑名单，返回一个集合
    """
    # 加载黑名单关键词
    blacklist = set()
    if os.path.exists(blacklist_path):
        encoding = detect_file_encoding(blacklist_path)
        with open(blacklist_path, 'r', encoding=encoding) as bl_file:
            for line in bl_file:
                keyword = line.strip()
                if keyword:
                    blacklist.add(keyword.lower())  # 统一小写比较，兼容英文
    else:
        print(f"未找到黑名单文件：{blacklist_path}")
    return blacklist
 
def generate_wordcloud(suffix_counter: Counter):
    """
    根据后缀频率生成词云并显示
    """
    if not suffix_counter:
        print("没有找到视频文件后缀，无法生成词云")
        return

    wordcloud = WordCloud(
        font_path='msyh.ttc',  # 微软雅黑字体
        width=800,
        height=600,
        background_color='white'
    ).generate_from_frequencies(suffix_counter)

    plt.figure(figsize=(10, 5))
    plt.imshow(wordcloud, interpolation='bilinear')
    plt.axis('off')
    plt.title('视频文件后缀词云')
    plt.tight_layout()
    plt.show()

def export_name_list(counter: Counter, export_path: str, top_k: int = 100):
    """
    将统计出的前 top_k 个视频文件名导出为文本文件
    每行一个名称，用于后续作为过滤关键词
    """
    if not counter:
        print("没有数据可导出")
        return

    with open(export_path, 'w', encoding='utf-8') as f:
        for name, count in counter.most_common(top_k):
            f.write(f"{name}\n")  # 只写名称，不含频率

    logger.success(f"已导出前 {top_k} 个视频文件名到 {export_path}")

if __name__ == "__main__":
    txt_path = "./目录树.txt"
    counter = extract_video_names(txt_path)
    generate_wordcloud(counter)
    export_path = "./test.txt"
    export_name_list(counter, export_path, top_k=100)