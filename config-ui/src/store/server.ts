import { createFetch } from "@vueuse/core"

export const useMyFetch = createFetch({
  baseUrl: import.meta.env.MODE == 'development' ? 'http://localhost:12333' : '',
  options: {
    timeout: 1000,
    onFetchError(ctx) {
      if (ctx.error.code == 20) {
        alert("保存失败，可能设置程序被关了")
      }
      return ctx
    }
  }
})


export const server = {
  runWindowSpy: () => useMyFetch('/server/command/2').post(),
  enableRunAtStartup: () => useMyFetch('/server/command/3').post(),
  disableRunAtStartup: () => useMyFetch('/server/command/4').post(),
}
