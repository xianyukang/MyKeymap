## <font color='#D05'>MyKeymap 简介</font>

#### ➤ 下载 & 文档

- [MyKeymap 1.0.0](https://xianyukang.com/MyKeymap.html#mykeymap-%E7%AE%80%E4%BB%8B)


#### ➤ b 站视频介绍

- [点此 link 跳转](https://www.bilibili.com/video/BV1Sf4y1c7p8)

#### ➤ MyKeymap 的作用是什么?  有哪些功能 ?

1. 减少使用鼠标的频率
2. 提升工作学习中编辑文字、整理笔记、切换窗口的效率
3. 掌握 MyKeymap 后，能让使用 Windows 的日常，拥有流畅、舒适、顺滑的操作体验

| <img src="https://static.xianyukang.com/MyKeymap-features.png" alt="image-20211004143651899"  /> | <img src="https://static.xianyukang.com/夏日大作战typing.gif" alt="Pin on Movies"  /> |
| ------------------------------------------------------------ | ------------------------------------------------------------ |



## <font color='#D05'>项目运行方法</font>

### 安装依赖

```bash
# 注意 windows-curses 包目前不支持 python 3.10.x
pip install -i https://pypi.tuna.tsinghua.edu.cn/simple flask flask_cors pyinstaller windows-curses

# 去 config-front 目录执行
npm --registry https://registry.npm.taobao.org install
```



### 运行调试

```bash
# 启动后端项目,  去 config-back 目录执行
python api.py --server

# 启动前端项目,  去 config-front 目录执行
npm run serve

# 然后访问 http://127.0.0.1:8080 查看页面
```



