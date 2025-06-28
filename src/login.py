import os  # 用于写入环境变量
import requests  # 用于发送 HTTP 请求
from loguru import logger  # 用于打印日志
ALIST_HOST = os.getenv("ALIST_HOST", "https://video.rock6rock.nyat.app:48158")
ALIST_PORT= os.getenv("ALIST_PORT", 5244)
ALIST_URL = f"{ALIST_HOST}:{ALIST_PORT}"
def login_get_token(username: str, password: str) -> str:
    """
    登录 Oplist API，获取 token 并写入环境变量

    :param username: 登录账号
    :param password: 登录密码
    :return: 返回 token 字符串
    """
    url = ALIST_URL + "/api/auth/login"  # 根据文档的登录地址

    payload = {
        "username": username,  # 请求体中的用户名
        "password": password   # 请求体中的密码
    }

    try:
        logger.info(f"开始请求登录接口，URL: {url}, 请求参数: {payload}")  # 新增：请求前记录请求参数
        response = requests.post(url, json=payload)  # 发送 POST 请求，json 参数会自动转为 JSON 格式
        response.raise_for_status()  # 如果返回状态码不是 2xx，会抛出异常
        logger.info(f"登录请求成功，响应内容: {response.json()}")  # 打印成功响应

        token = response.json().get("data").get("token")  # 提取返回的 token 字段
        if not token:
            logger.error("登录成功但未返回 token 字段")
            return None

        os.environ["OPLIST_TOKEN"] = token  # 将 token 写入环境变量
        logger.info("token 已成功写入环境变量 OPLIST_TOKEN")

        return token  # 返回 token

    except requests.RequestException as e:
        # 新增：详细打印请求失败时的所有上下文信息
        logger.error(f"请求异常，URL: {url}, 请求参数: {payload}")
        if e.response is not None:
            logger.error(f"请求失败状态码: {e.response.status_code}")
            try:
                logger.error(f"请求失败响应内容: {e.response.json()}")
            except Exception:
                logger.error(f"请求失败响应文本: {e.response.text}")
        logger.error(f"异常详情: {e}")
        return None

    except Exception as e:
        logger.error(f"处理响应时发生异常: {e}")  # 捕获其他异常
        return None

if __name__ == '__main__':
    login_get_token(" ", " ")