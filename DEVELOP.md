# Doc for Developers

## clone 代码仓库

```
git clone https://github.com/xianyukang/MyKeymap
```

## 技术框架

### bin

主要是[AutoHotkey](https://www.autohotkey.com/)代码，快捷键钩子、系统功能调用都在这里

### config-ui

vite+vue3 独立前端，用来维护修改配置

### config-server

go语言实现的后端，主要是两大功能：

+ 对于 bin：根据配置，调用 bin 代码完成核心
+ 对于 config-ui：实现 api 供其调用

## 开发调试

需要 make 构建工具 + go + node 环境

使用 make 执行对应操作，对哪一部分进行修改，开启对应的调试，或者直接修改对应的代码即可

### ui调试

进入 config-ui 目录，安装好依赖
```
make client
```

### server调试

```
make server
```

### bin

bin部分的代码和一些工具，可以直接修改或者替换

## 构建打包

需要 make 构建工具 + go + node 环境

和开发调试类似，在`Makefile`中可以找到对应命令
