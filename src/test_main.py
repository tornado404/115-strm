import unittest

from src.main import process


class MyTestCase(unittest.TestCase):
    def test_something(self):
        output_file = "./目录树.txt"
        process(output_file)


if __name__ == '__main__':
    unittest.main()
