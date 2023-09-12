export interface Action {
  isEmpty: boolean
  windowGroupID: number
  actionTypeID: number
  comment?: string

  actionValueID?: number

  remapToKey?: string
  keysToSend?: string
  ahkCode?: string

  winTitle?: string
  target?: string
  args?: string
  workingDir?: string
  runAsAdmin?: boolean
  runInBackground?: boolean
  detectHiddenWindow?: boolean

}
export interface Keymap {
  id: number
  name: string
  enable: boolean
  hotkey: string
  parentID: number
  hotkeys: {
    [key: string]: Array<Action>
  }
}

export interface Scroll {
  delay1: string
  delay2: string
  onceLineCount: string;
}

export interface Mouse {
  delay1: string
  delay2: string
  fastSingle: string
  fastRepeat: string
  slowSingle: string
  slowRepeat: string
  keepMouseMode: boolean
  showTip: boolean
  tipSymbol: string
}

export interface WindowGroup {
  id: number
  name: string
  value: string
  conditionType: number
}

export type PathVariable = {
  name: string
  value: string
}

export interface Options {
  mykeymapVersion: string
  scroll: Scroll
  mouse: Mouse
  windowGroups: Array<WindowGroup>
  pathVariables: Array<PathVariable>
  customShellMenu: string
  startup: boolean
  keyMapping: string
  keyboardLayout: string
}

export interface Config {
  keymaps: Array<Keymap>
  options: Options
}
