export const predefinedApps = [
  {
    name: "普通应用:",
    apps: [
      {
        comment: "文件管理器",
        toActivate: "ahk_class CabinetWClass ahk_exe Explorer.EXE",
        toRun: "D:\\",
      },
      {
        comment: "Everything",
        toActivate: "ahk_class EVERYTHING",
        toRun: "C:\\Program Files\\Everything\\Everything.exe",
      },
      {
        comment: "Chrome",
        toActivate: "ahk_exe chrome.exe",
        toRun: "C:\\ProgramData\\Microsoft\\Windows\\Start Menu\\Programs\\Google Chrome.lnk",
      },
      {
        comment: "Edge",
        toActivate: "ahk_exe msedge.exe",
        toRun: "C:\\ProgramData\\Microsoft\\Windows\\Start Menu\\Programs\\Microsoft Edge.lnk",
      },
      {
        comment: "Firefox",
        toActivate: "ahk_exe firefox.exe",
        toRun: "C:\\ProgramData\\Microsoft\\Windows\\Start Menu\\Programs\\Firefox.lnk",
      },
    ],
  },
  {
    name: "通讯软件",
    apps: [
      {
        comment: "TIM",
        toActivate: "if_exist_then_send: TIM.exe, ^!z",
        toRun: "C:\\ProgramData\\Microsoft\\Windows\\Start Menu\\Programs\\腾讯软件\\TIM\\TIM.lnk",
      },
      {
        comment: "QQ",
        toActivate: "if_exist_then_send: QQ.exe, ^!z",
        toRun: "C:\\ProgramData\\Microsoft\\Windows\\Start Menu\\Programs\\腾讯软件\\QQ\\腾讯QQ.lnk",
      },
      {
        comment: "微信",
        toActivate: "if_exist_then_send: WeChat.exe, ^!w",
        toRun: "C:\\ProgramData\\Microsoft\\Windows\\Start Menu\\Programs\\微信\\微信.lnk",
      },
      {
        comment: "企业微信",
        toActivate: "if_exist_then_send: WXWork.exe, +!s",
        toRun: "C:\\ProgramData\\Microsoft\\Windows\\Start Menu\\Programs\\企业微信\\企业微信.lnk",
      },
      {
        comment: "Steam",
        toActivate: "ahk_exe steam.exe",
        toRun: "C:\\Program Files (x86)\\Steam\\steam.exe",
      },
    ],
  },
  {
    name: "多媒体软件",
    apps: [
      {
        comment: "网易云音乐",
        toActivate: "detect_hidden_window: ahk_class OrpheusBrowserHost",
        toRun: "C:\\ProgramData\\Microsoft\\Windows\\Start Menu\\Programs\\网易云音乐\\网易云音乐.lnk",
      },
      {
        comment: "QQ音乐 UWP",
        toActivate: "QQ音乐UWP",
        toRun: "shortcuts\\QQ音乐UWP.lnk",
      },
      {
        comment: "QQ音乐桌面版",
        toActivate: "if_exist_then_send: QQMusic.exe, ^!q",
        toRun: "C:\\ProgramData\\Microsoft\\Windows\\Start Menu\\Programs\\腾讯软件\\QQ音乐\\QQ音乐.lnk",
      },
      {
        comment: "PotPlayer",
        toActivate: "ahk_class PotPlayer64",
        toRun: "C:\\ProgramData\\Microsoft\\Windows\\Start Menu\\Programs\\Daum\\PotPlayer 64 bit\\PotPlayer 64 bit.lnk",
      },
      {
        comment: "Spotify 网页",
        toActivate: "Spotify",
        toRun: "https://open.spotify.com/",
      },
    ],
  },
  {
    name: "文档和笔记",
    apps: [
      {
        comment: "Excel",
        toActivate: "ahk_exe EXCEL.EXE",
        toRun: "C:\\ProgramData\\Microsoft\\Windows\\Start Menu\\Programs\\Excel.lnk",
      },
      {
        comment: "PowerPoint",
        toActivate: "ahk_exe POWERPNT.EXE",
        toRun: "C:\\ProgramData\\Microsoft\\Windows\\Start Menu\\Programs\\PowerPoint.lnk",
      },
      {
        comment: "Word",
        toActivate: "ahk_exe WINWORD.EXE",
        toRun: "C:\\ProgramData\\Microsoft\\Windows\\Start Menu\\Programs\\Word.lnk",
      },
      {
        comment: "WPS Office",
        toActivate: "ahk_exe wps.exe",
        toRun: "%A_Programs%\\WPS Office\\WPS Office.lnk",
      },
      {
        comment: "Typora",
        toActivate: "ahk_exe Typora.exe",
        toRun: "C:\\Program Files\\Typora\\Typora.exe",
      },
      {
        comment: "OneNote UWP",
        toActivate: "OneNote for Windows 10",
        toRun: "shortcuts\\OneNote for Windows 10.lnk",
      },
    ],
  },
  {
    name: "编程软件:",
    apps: [
      {
        comment: "VSCode",
        toActivate: "ahk_exe Code.exe",
        toRun: "%A_Programs%\\Visual Studio Code\\Visual Studio Code.lnk",
      },
      {
        comment: "Windows Terminal",
        toActivate: "ahk_exe WindowsTerminal.exe",
        toRun: "wt.exe",
      },
      {
        comment: "Visual Studio",
        toActivate: "- Microsoft Visual Studio",
        toRun: "C:\\ProgramData\\Microsoft\\Windows\\Start Menu\\Programs\\Visual Studio 2019.lnk",
      },
      {
        comment: "IntelliJ IDEA",
        toActivate: "ahk_exe idea64.exe",
        toRun: "%A_Programs%\\JetBrains Toolbox\\IntelliJ IDEA Ultimate.lnk",
      },
      {
        comment: "GoLand",
        toActivate: "ahk_exe goland64.exe",
        toRun: "%A_Programs%\\JetBrains Toolbox\\GoLand.lnk",
      },
      {
        comment: "WebStorm",
        toActivate: "ahk_exe webstorm64.exe",
        toRun: "%A_Programs%\\JetBrains Toolbox\\WebStorm.lnk",
      },
      {
        comment: "DataGrip",
        toActivate: "ahk_exe datagrip64.exe",
        toRun: "%A_Programs%\\JetBrains Toolbox\\DataGrip.lnk",
      },
    ],
  },
]
