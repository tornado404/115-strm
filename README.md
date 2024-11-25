# 115-strm
通过115网盘生成下载目录树，自动生成strm文件，使用alist的情况下，可添加到emby进行播放，并且支持将目录树导入到alist的索引数据库，目前只测试音乐，其他多媒体格式应也是可以的，

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

在线下载
https://flac.life/

# 测试环境
系统ubuntu20
安装好python
执行需要sudo权限

# 先去生成文件的目录树
https://115.com/115115/T496626.html
最好是将要处理的文件放在一个目录
将目录树放到ubuntu的目录
# strm生成部分
最好在存放目录树的地方执行脚本
```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/suixing8/115-strm/main/115-strm-alist.sh)"
```
# 具体
请选择操作：
1: 将目录树转换为目录文件
2: 生成 .strm 文件
0: 退出

先选择1，
输入文件树的路劲

生成之后会返回主页，选择2，进行生成strm文件<br><br>

![image](https://github.com/user-attachments/assets/a1f072b6-2660-4f05-a315-5b93b4ab5ecf)<br><br>

输入 .strm 文件保存的路径

输入剔除选项（输入要剔除的目录层级数量）：

这个主要的目的就是为了生成的strm结构能和alist的结构一致，我贴出我的示例
我在alist挂载的是music这个目录，alist挂载是不显示music这个目录，直接显示music目录下的文件<br><br>
![image](https://github.com/user-attachments/assets/53fb66f0-93fb-4948-afe7-00c2554b4373)<br><br>

比如我的115目录是/alist/music/A.歌手歌单，要处理的是/music这个文件夹<br><br>

![image](https://github.com/user-attachments/assets/eefc6cd6-e6b1-49b3-b89e-30e14f042e59)<br><br>

115目录树在生成的时候，会多自动多生成建立目录树文件的上一级目录
也就是我生成music这个文件夹的目录树的时候，目录树会生成/alist/music
所以115自动生成的目录树对于alist来说，多了2层目录，所以这种情况下，目录层级数量输入2，看不懂就多实践<br><br>
![image](https://github.com/user-attachments/assets/9d0a45a1-42b1-4f56-87be-b337c9dbe3ba)<br><br>

输入alist的ip地址+端口，等待处理后，strm文件创建到此结束

![image](https://github.com/user-attachments/assets/772c2ab2-a8d4-451e-be2d-36322fbcc2ee)<br><br>



# alist建立索引数据库

alsit版本不能太低，最好在v3.7以后的版本

将alsit停止后，备份data.db数据库，将data.db数据库文件存放到脚本执行的目录

在主页面选择3
脚本会自动获取当前的文件提供选择
剔除路径和strm同理<br><br>
![image](https://github.com/user-attachments/assets/965cbdcd-20cc-437c-b722-73b711f25a97)<br><br>

根据实际情况选择替换还是新增到数据路的索引表，这个只会修改数据库的索引表，不会进行其他操作<br><br>

![image](https://github.com/user-attachments/assets/e41992c2-7842-40fb-80d3-abda16ec7864)<br><br>

将data.db上传到alist目录，替换data.db，再次提醒data.db提前备份<br><br>

![image](https://github.com/user-attachments/assets/47a876cb-9686-406a-a0fc-848488be1de7)<br><br>


开启alist，以下为效果，理论上，你可以将整个115网盘都挂载到alist，并且在alist上就可以搜索和观看<br><br>

![image](https://github.com/user-attachments/assets/a38c96e5-f4fb-4790-9da9-b422bab1d5ee)<br><br>


如果你是苹果手机，推荐使用Fileball，使用alist添加后，不能是webdav的方式添加，添加后，选择搜索，全局搜索，可以直接调用alist的api进行搜索
这个比较适合看电影电视剧综艺，因为Fileball不支持音乐，这个是目前我所使用的众多app中，唯一一个支持调用alist搜索api的<br><br>

![4261a8529bb4f3a4083fb4e54eddbd1](https://github.com/user-attachments/assets/9d4f8d0e-51aa-40ae-9f2a-94200ac96aa9)<br><br>


# 最后，转发请注明出处
感谢ChatGPT-40提供的代码<br><br>
联系https://t.me/gengpengw




