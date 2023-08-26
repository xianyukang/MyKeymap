import { useFetch } from "@vueuse/core"

export const server = {
  runWindowSpy: () => useFetch('http://localhost:12333/server/command/2').post(),
}
