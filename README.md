# 115-strm
通过115网盘生成下载目录树，自动生成strm文件，使用alist的情况下，可添加到emby进行播放，目前只测试音乐，其他多媒体格式应也是可以的，后面有空的时候，会写一个脚本，将目录树导入到alist的搜索索引数据库

# 分享音乐
https://115.com/s/swhsphs33xj?password=0000#
音乐22万首14.39T音乐包1
访问码：0000

https://115.com/s/swhsphb33xj?password=0000#
音乐22万首14.39T音乐包2
访问码：0000

https://115.com/s/swhspho33xj?password=0000#
音乐22万首14.39T音乐包3
访问码：0000


# 测试环境
系统ubuntu20
安装好python
执行需要sudo权限

# 1.先去生成文件的目录树
https://115.com/115115/T496626.html
最好是将要处理的文件放在一个目录
将目录树放到ubuntu的目录
# 执行脚本
最好在存放目录树的地方执行脚本
```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/suixing8/115-strm/main/115-strm.sh)"
```
# 具体
请选择操作：
1: 将目录树转换为目录文件
2: 生成 .strm 文件
0: 退出

先选择1，
输入文件树的路劲

生成之后会返回主页，选择2，进行生成strm文件<br>

![image](https://github.com/user-attachments/assets/a1f072b6-2660-4f05-a315-5b93b4ab5ecf)

输入 .strm 文件保存的路径

输入剔除选项（输入要剔除的目录层级数量）：

这个主要的目的就是为了生成的strm结构能和alist的结构一只，我贴出我的示例
我在alist挂载的是music这个目录，alist挂载是不显示music这个目录，直接显示music目录下的文件
![image](https://github.com/user-attachments/assets/53fb66f0-93fb-4948-afe7-00c2554b4373)

比如我的115目录是/alist/music/A.歌手歌单，要处理的是/music这个文件夹

![image](https://github.com/user-attachments/assets/eefc6cd6-e6b1-49b3-b89e-30e14f042e59)

115目录树在生成的时候，会多自动多生成建立目录树文件的上一级目录
也就是我生成music这个文件夹的目录树的时候，目录树会生成/alist/music
所以115自动生成的目录树对于alist来说，多了2层目录，所以这种情况下，目录层级数量输入2，看不懂就多实践
![image](https://github.com/user-attachments/assets/9d0a45a1-42b1-4f56-87be-b337c9dbe3ba)

输入alist的ip地址+端口

![image](https://github.com/user-attachments/assets/772c2ab2-a8d4-451e-be2d-36322fbcc2ee)



