import { createFetch } from "@vueuse/core"
import { MidiPorts } from "@/types/config"

export const useMyFetch = createFetch({
  baseUrl: import.meta.env.MODE == 'development' ? 'http://localhost:12333' : '',
  options: {
  }
})


export const server = {
  runWindowSpy: () => useMyFetch('/server/command/2').post(),
  enableRunAtStartup: () => useMyFetch('/server/command/3').post(),
  disableRunAtStartup: () => useMyFetch('/server/command/4').post(),
  getMidiPorts: () => useMyFetch('/midi-ports').json<MidiPorts>(),
}
