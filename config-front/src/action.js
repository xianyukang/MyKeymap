// 分组、根据 value 获取 label 数据
import { bindWindow } from './util';
import _, { join } from 'lodash'

export const specialAction = {
    bindWindowToCurrentKey: {
        label: "绑定活动窗口到当前键",
        generateValue: (routeName, currentKey) => bindWindow(routeName, currentKey),
    },
}


export const windowActions1 = [
    { label: "关闭窗口", value: "SmartCloseWindow()" },
    { label: "切换到上一个窗口", value: "send, !{tab}" },
    { label: "在当前程序的窗口间切换", value: "SwitchWindows()" },
    { label: "窗口管理器(EDSF切换、X关闭、空格选择)", value: "action_enter_task_switch_mode()", },
    { label: "上一个虚拟桌面", value: "send, {LControl down}{LWin down}{Left}{LWin up}{LControl up}", },
    { label: "下一个虚拟桌面", value: "send, {LControl down}{LWin down}{Right}{LWin up}{LControl up}", },
    { label: "移动窗口到下一个显示器", value: "send, #+{right}" },
]

export const windowActions2 = [
    { label: "窗口最大化", value: "winmaximize, A" },
    { label: "窗口最小化", value: "winMinimizeIgnoreDesktop()" },
    { label: "窗口居中(1200x800)", value: "center_window_to_current_monitor(1200, 800)", },
    { label: "窗口居中(1370x930)", value: "center_window_to_current_monitor(1370, 930)", },
    { label: "切换窗口置顶状态", value: "ToggleTopMost()" },
    { label: "上一个窗口 (Alt+Esc)", value: "send, !{Esc}" },
    { label: "下一个窗口 (Shift+Alt+Esc)", value: "send, +!{Esc}" },
]


export const mouseActions = [
    { label: "鼠标上移", value: "鼠标上移" },
    { label: "鼠标下移", value: "鼠标下移" },
    { label: "鼠标左移", value: "鼠标左移" },
    { label: "鼠标右移", value: "鼠标右移" },
]
export const scrollActions = [
    { label: "滚轮上滑", value: "滚轮上滑" },
    { label: "滚轮下滑", value: "滚轮下滑" },
    { label: "滚轮左滑", value: "滚轮左滑" },
    { label: "滚轮右滑", value: "滚轮右滑" },
]
export const clickActions = [
    { label: "鼠标左键", value: "鼠标左键" },
    { label: "鼠标右键", value: "鼠标右键" },
    { label: "鼠标左键按下", value: "鼠标左键按下" },
    { label: "移动鼠标到窗口中心", value: "移动鼠标到窗口中心" },
    { label: "让当前窗口进入拖动模式", value: "让当前窗口进入拖动模式" },
]

export const textFeatures1 = [
    { label: "把选中的文字设为红色", value: 'setColor("#D05")' },
    { label: "把选中的文字设为紫色", value: 'setColor("#b309bb")' },
    { label: "把选中的文字设为粉色", value: 'setColor("#FF00FF")' },
    { label: "把选中的文字设为蓝色", value: 'setColor("#2E66FF")' },
    { label: "把选中的文字设为绿色", value: 'setColor("#080")' },
]
export const textFeatures2 = [
    {
        label: "在中英文之间添加空格",
        value: "actionAddSpaceBetweenEnglishChinese()",
    },
]



export const getLabelByValue = [
    ...windowActions1, ...windowActions2, ...mouseActions, ...scrollActions, ...clickActions,
    ...textFeatures1, ...textFeatures2
].reduce((a, b) => { a[b.value] = b.label; return a }, {})