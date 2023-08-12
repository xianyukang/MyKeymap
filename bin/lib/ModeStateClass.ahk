class ModeStateClass {
  currentName := ""
  currentRef := false
  locked := false

  ; 启动当前模式
  startCurrentMode() {
   %this.currentRef% := true
  }
  
  ; 关闭当前模式
  closeCurrentMode() {
    %this.currentRef% := false
  }

  ; 修改当前模式状态，对当前模式的状态取反
  changeState() {
    %this.currentRef% := !this.currentRef
  }
}