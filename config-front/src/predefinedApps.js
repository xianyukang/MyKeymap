export const predefinedApps = [
  {
    name: "普通应用:",
    apps: [
      {
        comment: "Everything",
        toActivate: "ahk_class EVERYTHING",
        toRun: "%A_ProgramFiles%\\Everything\\Everything.exe",
      },
    ],
  },
  {
    name: "编程软件:",
    apps: [],
  },
  {
    name: "通讯软件",
    apps: [
      {
        comment: "TIM",
        toActivate: "if_exist_then_send: TIM.exe, ^!z",
        toRun: "%A_ProgramsCommon%\\腾讯软件\\TIM\\TIM.lnk",
      },
    ],
  },
  {
    name: "音乐软件",
    apps: [
      {
        comment: "网易云音乐桌面版",
        toActivate: "detect_hidden_window: ahk_class OrpheusBrowserHost",
        toRun: "%A_ProgramsCommon%\\网易云音乐\\网易云音乐.lnk",
      },
    ],
  },
  {
    name: "浏览器",
    apps: [
      {
        comment: "Chrome",
        toActivate: "ahk_exe chrome.exe",
        toRun: "%A_ProgramsCommon%\\Google Chrome.lnk",
      },
      {
        comment: "Edge",
        toActivate: "ahk_exe msedge.exe",
        toRun: "%A_ProgramsCommon%\\Microsoft Edge.lnk",
      },
    ],
  },
]
