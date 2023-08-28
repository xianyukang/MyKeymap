export interface Action {
  isEmpty: boolean
  windowGroupID: number
  actionTypeID: number
  comment?: string

  actionValueID?: number

  remapToKey?: string
  keysToSend?: string

  winTitle?: string
  target?: string
  args?: string
  workingDir?: string
  runAsAdmin?: boolean
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
}

export interface WindowGroup {
  id: number
  name: string
  value: string
  conditionType: number
}

export interface Path {
  "key": string
  "value": string
}

export interface Options {
  scroll: Scroll
  mouse: Mouse
  windowGroups: Array<WindowGroup>
  path: Array<Path>
  customShellMenu: string
  startup: boolean
  keyMapping: string
}

export interface Config {
  keymaps: Array<Keymap>
  options: Options
}
