interface Action {
  windowGroupID: number;
  actionTypeID: number;
  remapToKey: string
}
interface Keymap {
  id: number;
  name: string;
  enable: boolean;
  hotkey: string;
  parentID: number
  hotkeys: {
    [key: string]: Array<Action>
  }
  extraHotkeys: string[]
}

interface Scroll {
  delay1: string;
  delay2: string;
  onceLineCount: string;
}

interface Mouse {
  delay1: string,
  delay2: string,
  single: string;
  repeat: string;
}

interface WindowGroup {
  id: number;
  name: string;
  value: string;
  conditionType: number
}

interface Path {
  "key": string;
  "value": string;
}

interface Options {
  scroll: Scroll;
  fastMouse: Mouse;
  slowMouse: Mouse;
  windowGroups: Array<WindowGroup>;
  path: Array<Path>;
  customShellMenu: string;
  startup: boolean;
  keyMapping: string;
}

interface Config {
  keymaps: Array<Keymap>;
  options: Options;
  capsAbbr: Array<{[key: string]: Array<Action>}>;
  semicolonAbbr: Array<{[key: string]: Array<Action>}>;
}
