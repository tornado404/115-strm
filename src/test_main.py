import unittest

from src.main import process
import os
import shutil


# class MyTestCase(unittest.TestCase):
#     def test_something(self):
#         # 临时设置环境变量
#         os.environ["STRM_SAVE_PATH"] = "../testdata"
#         # 确保测试目录存在
#         os.makedirs("../testdata", exist_ok=True)
#         output_file = "./目录树.txt"
#         process(output_file)

# 测试文件存储
# /data/
class TestFileStorage(unittest.TestCase):
    def test_file_storage(self):
        # 确保测试目录存在
        adjusted_path = "媒体库/福利吧/259LUXU-1520 ラグジュTV 1500 モデルの様なスタイルと愛らしいルックスを持つ美女が登場。緊張しながらも昂った身体は「責められたい」願望に満たされ、徐々に妖艶な表情を浮かべる。オイルで怪しい輝きを纏った美しい体は、非日常の刺激に敏感に反応し喘ぎ乱れる！.mp4"
        print(f"length of adjusted_path is {len(adjusted_path)}")
        if len(adjusted_path) > 100:
            parts = adjusted_path.split('/')
            if parts:
                # 提取最后一个路径段（文件名或目录名）
                last_part = parts[-1]
                # 缩短为前20个字符
                shortened_last = last_part[:20]
                # 替换原路径中的最后一段为缩短后的
                parts[-1] = shortened_last
                # 重新组合成路径
                adjusted_path = '/'.join(parts)
        print(len(adjusted_path))
        print(adjusted_path)

if __name__ == '__main__':
    unittest.main()
