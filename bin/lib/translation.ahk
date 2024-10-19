class DefaultTranslation {
  mykeymap_on := "🚀  MyKeymap: On  "
  mykeymap_off := "⏸️  MyKeymap: Off  "
  
  menu_pause := "Pause"
  menu_exit := "Exit"
  menu_reload := "Reload"
  menu_settings := "Settings"
  menu_window_spy := "Window Spy"

  no_items_selected := "no items selected"
  always_on_top_on := "Always-on-top: On"
  always_on_top_off := "Always-on-top: Off"
  copy_failed := " Copy: fail "
  copy_ok := " Copy: ok "
  mute_on := "Mute: On"
  mute_off := "Mute: Off"
  mute_falied := "Cannot mute this app"
}

class ChineseTranslation extends DefaultTranslation {
  mykeymap_on :=  "🚀  恢复 MyKeymap  "
  mykeymap_off := "⏸️  暂停 MyKeymap  "

  menu_pause := "暂停"
  menu_exit := "退出"
  menu_reload := "重启程序"
  menu_settings := "打开设置"
  menu_window_spy := "查看窗口标识符"

  no_items_selected := "没有选中的文本或文件"
  always_on_top_on := "置顶当前窗口"
  always_on_top_off := "取消置顶"
  copy_failed := "复制失败"
  copy_ok := "复制成功"
  mute_on := "静音当前应用"
  mute_off := "取消静音"
  mute_falied := "无法静音此应用"
}


Translation() {
  static t := SysLangIsChinese() ? ChineseTranslation() : DefaultTranslation()
  return t
}

SysLangIsChinese()
{
  ; https://www.autohotkey.com/docs/v2/misc/Languages.htm
  m := Map(
    "7804", "Chinese",  ; zh
    "0004", "Chinese (Simplified)",  ; zh-Hans
    "0804", "Chinese (Simplified, China)",  ; zh-CN
    "1004", "Chinese (Simplified, Singapore)",  ; zh-SG
    "7C04", "Chinese (Traditional)",  ; zh-Hant
    "0C04", "Chinese (Traditional, Hong Kong SAR)",  ; zh-HK
    "1404", "Chinese (Traditional, Macao SAR)",  ; zh-MO
    "0404", "Chinese (Traditional, Taiwan)",  ; zh-TW
  )
  return m.Get(A_Language, false)
}