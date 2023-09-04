import { useFetch } from "@vueuse/core"

export const server = {
  runWindowSpy: () => useFetch('http://localhost:12333/server/command/2').post(),
  enableRunAtStartup: () => useFetch('http://localhost:12333/server/command/3').post(),
  disableRunAtStartup: () => useFetch('http://localhost:12333/server/command/4').post(),
}
