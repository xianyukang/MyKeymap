export const languageList = [
  { title: '简体中文', value: 'zh' },
  { title: 'English', value: 'en' },
]

export const languageMap = {
  // window
  1: { zh: "关闭窗口", en: "Close", },
  2: { zh: "切换到上一个窗口", en: "Previous window", },
  3: { zh: "在当前程序的窗口间轮换", en: "Cycle through app windows", },
  4: { zh: "窗口管理 (EDSF切换X关闭,空格选择)", en: "Task switcher (EDSF=↑↓←→,X=Delete", },
  5: { zh: "上一个虚拟桌面", en: "Previous virtual desktop", },
  6: { zh: "下一个虚拟桌面", en: "Next virtual desktop", },
  7: { zh: "移动窗口到下一个显示器", en: "Move window to next monitor", },
  8: { zh: "关闭窗口 (杀进程)", en: "Kill the active process", },
  9: { zh: "关闭同类窗口", en: "Close all app windows", },
  10: { zh: "窗口最小化", en: "Minimize", },
  11: { zh: "窗口最大化或还原", en: "Maximize", },
  12: { zh: "窗口居中 (1200x800)", en: "Center (1200x800)", },
  13: { zh: "窗口居中 (1370x930)", en: "Center (1370x930)", },
  14: { zh: "切换窗口置顶状态", en: "Always on top", },
  15: { zh: "让窗口随鼠标拖动", en: "Drag window", },
  16: { zh: "绑定当前窗口 (长按绑定,短按激活)", en: "Bind window by long press", },

  // system
  17: { zh: "锁屏", en: "Lock the screen", },
  18: { zh: "睡眠", en: "Sleep", },
  19: { zh: "关机", en: "Shutdown", },
  20: { zh: "重启", en: "Reboot", },
  21: { zh: "音量调节", en: "Volume control", },
  22: { zh: "显示器亮度调节", en: "Monitor brightness control", },
  23: { zh: "重启文件资源管理器", en: "Restart explorer.exe", },
  24: { zh: "复制文件路径或纯文本", en: "Copy full path of a file ", },
  2401: { zh: "静音当前应用", en: "Mute active app", },

  // mouse
  25: { zh: "鼠标上移", en: "Mouse up" },
  26: { zh: "鼠标下移", en: "Mouse down" },
  27: { zh: "鼠标左移", en: "Mouse left" },
  28: { zh: "鼠标右移", en: "Mouse right" },
  29: { zh: "滚轮上滑", en: "Wheel up" },
  30: { zh: "滚轮下滑", en: "Wheel down" },
  31: { zh: "滚轮左滑", en: "Wheel left" },
  32: { zh: "滚轮右滑", en: "Wheel right" },
  33: { zh: "鼠标左键", en: "Left button" },
  34: { zh: "鼠标右键", en: "Right button" },
  35: { zh: "鼠标中键", en: "Middle button" },
  36: { zh: "鼠标左键按下 (之后按空格松开)", en: "Left button down ( Space=Release )", },
  37: { zh: "移动鼠标到活动窗口", en: "Move mouse to active window", },

  // text
  38: { zh: "光标 - 上移", en: "Up" },
  39: { zh: "光标 - 下移", en: "Down" },
  40: { zh: "光标 - 左移", en: "Left" },
  41: { zh: "光标 - 右移", en: "Right" },
  42: { zh: "光标 - 跳到行首", en: "Home" },
  43: { zh: "光标 - 跳到行尾", en: "End" },
  44: { zh: "光标 - 上一单词", en: "Ctrl + Left" },
  45: { zh: "光标 - 下一单词", en: "Ctrl + Right" },

  46: { zh: "选择 - 往上", en: "Shift + Up" },
  47: { zh: "选择 - 往下", en: "Shift + Down" },
  48: { zh: "选择 - 往左", en: "Shift + Left" },
  49: { zh: "选择 - 往右", en: "Shift + Right" },
  50: { zh: "选择 - 选到行首", en: "Shift + Home" },
  51: { zh: "选择 - 选到行尾", en: "Shift + End" },
  52: { zh: "选择 - 上一单词", en: "Ctrl+Shift+Left" },
  53: { zh: "选择 - 下一单词", en: "Ctrl+Shift+Right" },

  54: { zh: "右键菜单", en: "Menu key" },
  55: { zh: "删除一行文本", en: "Delete a line" },
  56: { zh: "删除一个单词", en: "Delete a word" },
  57: { zh: "Shift 键", en: "Shift" },
  58: { zh: "Ctrl 键", en: "Ctrl" },
  59: { zh: "Alt 键", en: "Alt" },
  60: { zh: "Win 键", en: "Win" },
  61: { zh: "中英文之间加空格", en: "中英文间加空格" },

  62: { en: "Esc" },
  63: { en: "Backspace" },
  64: { en: "Enter" },
  65: { en: "Delete" },
  66: { en: "Insert" },
  67: { en: "Tab" },
  68: { en: "Ctrl + Tab" },
  69: { en: "Shift + Tab" },
  70: { en: "Ctrl+Shift+Tab" },

  // MyKeymap
  71: { zh: "暂停 MyKeymap", en: "Pause" },
  72: { zh: "重启 MyKeymap", en: "Reload" },
  73: { zh: "退出 MyKeymap", en: "Exit" },
  74: { zh: "打开 MyKeymap 设置", en: "Settings" },

  75: { zh: "触发 Abbreviation", en: "Abbreviation" },
  76: { zh: "触发 Command", en: "Command" },
  77: { zh: "切换 CapsLock 大小写", en: "CapsLock" },
  78: { zh: "锁定当前模式 (免去按住触发键)", en: "Hold down/release the modifier key" },

  // Action types
  200: { zh: "⛔ 未配置", en: "⛔ Undefined" },
  201: { zh: "🚀 启动程序或激活窗口", en: "🚀 App Launcher" },
  202: { zh: "🖥️ 系统控制", en: "🖥️ System" },
  203: { zh: "🏠 窗口操作", en: "🏠 Window" },
  204: { zh: "🖱️  鼠标操作", en: "🖱️  Mouse" },
  205: { zh: "🅰️ 重映射按键", en: "🅰️ Remap Keys" },
  206: { zh: "🅰️ 输入按键或文本", en: "🅰️ Send Keys" },
  207: { zh: "📚 文字编辑相关", en: "📚 Edit" },
  208: { zh: "⚛️ 一些内置函数", en: "⚛️ Built-in Functions" },
  209: { zh: "⚙️ MyKeymap 相关", en: "⚙️ MyKeymap" },

  // App Launcher
  301: { zh: "要激活的窗口 (窗口标识符)", en: "The window to activate" },
  302: { zh: "当窗口不存在时要启动的: 程序 / 文件夹 / URL", en: "Target" },
  303: { zh: "命令行参数", en: "Arguments" },
  304: { zh: "工作目录", en: "Working directory" },
  305: { zh: "备注", en: "Comment" },
  306: { zh: "以管理员运行", en: "Admin" },
  307: { zh: "后台运行", en: "Hide" },
  308: { zh: "检测隐藏窗口", en: "Detect hidden windows" },
  309: { zh: "🔍 查看窗口标识符", en: "🔍 Window Spy" },

  // Other
  401: { zh: "重映射为", en: "Remap to" },
  402: { zh: "要输入的按键或文本", en: "Keys" },
  403: { zh: "代码", en: "Code" },
  404: { zh: "热键", en: "Hotkey" },
  405: { zh: "新增一个", en: "Add" },

  // Settings
  501: { zh: "名称", en: "Name" },
  502: { zh: "触发键", en: "Modifer" },
  503: { zh: "上层", en: "Parent" },
  504: { zh: "开关", en: "" },
  505: { zh: "其他设置", en: "Other" },
  506: { zh: "开机自启", en: "Run on system startup" },
  507: { zh: "保存配置（CTRL+S）", en: "Save（CTRL+S）" },


  // Window Groups
  601: { zh: "😺 编辑程序分组", en: "😺 Window Groups" },
  602: { zh: "组名", en: "Group Name" },
  603: { zh: "窗口标识符", en: "Window List" },
  604: { zh: "条件", en: "Condition" },
  605: { zh: "是前台窗口", en: "is active" },
  606: { zh: "这些窗口存在", en: "exist" },
  607: { zh: "不是前台窗口", en: "not active" },
  608: { zh: "这些窗口不存在", en: "not exist" },
  609: { zh: "添加一行", en: "Add" },
  610: { zh: "保存", en: "Save" },
  611: { zh: "取消", en: "Cancel" },

  // Mouse Options
  701: { zh: "🖱️ 修改鼠标参数", en: "🖱️ Mouse Options" },
  702: { zh: "鼠标移动相关参数", en: "Mouse Options" },
  703: { zh: "进入连续移动前的延时(秒)", en: "Delay 1" },
  704: { zh: "两次移动的间隔时间(秒)", en: "Delay 2" },
  705: { zh: "快速模式步长(像素)", en: "Length 1" },
  706: { zh: "快速模式首步长(像素)", en: "Length 2" },
  707: { zh: "慢速模式步长(像素)", en: "Length 3" },
  708: { zh: "慢速模式首步长(像素)", en: "Length 4" },
  709: { zh: "鼠标模式的提示符", en: "Prompt" },
  710: { zh: "提示进入了鼠标模式", en: "Show prompt" },
  711: { zh: "点击鼠标后不退出鼠标模式", en: "Use only the space key to exit" },
  712: { zh: "滚轮相关参数", en: "Scroll Wheel Options" },
  713: { zh: "进入连续滚动前的延时 (秒)", en: "Delay 1" },
  714: { zh: "两次滚动的间隔时间 (越小滚动速度越快)", en: "Delay 2" },
  715: { zh: "一次滚动的行数", en: "Lines to scroll at a time" },

  // Keyboard Layout
  721: { zh: "⌨️ 修改键盘布局", en: "⌨️ Keyboard Layout" },
  722: { zh: "键盘布局", en: "Keyboard Layout" },
  723: { zh: "重置为默认值", en: "Default" },
  724: { zh: "重置为 74 键", en: "74 Key" },
  725: { zh: "重置为 104 键", en: "104 Key" },
  726: { zh: "添加鼠标按钮", en: "Add Mouse Buttons" },

  // Command Window
  741: { zh: "✨ 命令框皮肤", en: "✨ Command Window" },
  742: { zh: "命令框皮肤", en: "Command Window" },
  743: { zh: "窗口宽度", en: "Width" },
  744: { zh: "窗口 Y 轴位置 (百分比)", en: "Y pos" },
  745: { zh: "窗口圆角大小", en: "Border radius" },
  746: { zh: "窗口动画持续时间", en: "Animation duration" },
  747: { zh: "窗口背景色", en: "Background color" },
  748: { zh: "透明度", en: "Opacity" },
  749: { zh: "网格线颜色", en: "Gridline color" },
  750: { zh: "边框宽度", en: "Border width" },
  751: { zh: "边框颜色", en: "Border color" },
  752: { zh: "按键颜色", en: "Key color" },
  753: { zh: "四角颜色", en: "Corner color" },
  754: { zh: "窗口阴影大小", en: "Drop shadow size" },
  755: { zh: "窗口阴影颜色", en: "Drop shadow color" },


  761: { zh: "🕗 设置触发延时", en: "🕗 Modifer Delay" },
  762: { zh: "触发延时 (毫秒)", en: "Modifer Delay (ms)" },
  763: { zh: "一般推荐设为 0，让模式立刻生效。", en: "If delay > 0, you need long press to use the keymap." },
  764: { zh: "如果设置大于零的值，即通过长按触发模式，也许能减少打字误触。", en: "" },
  765: { zh: "但会有另一种形式的误触，比如想输入热键，但长按时间不够，所以触发热键失败。", en: "" },

  781: { zh: "🌐 切换语言", en: "🌐 Change Language" },



};
