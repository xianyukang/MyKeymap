//go:build windows

package midi

import (
	"syscall"
	"unsafe"
)

// 通过标准库 syscall 直接调用 winmm.dll, 不引入任何第三方依赖
var (
	winmm                  = syscall.NewLazyDLL("winmm.dll")
	procMidiOutGetNumDevs  = winmm.NewProc("midiOutGetNumDevs")
	procMidiOutGetDevCapsW = winmm.NewProc("midiOutGetDevCapsW")
)

const (
	// MIDIOUTCAPS 结构体在 32/64 位下的字节大小
	midiOutCapsSize = 84

	// szPname 在 MIDIOUTCAPS 中的字节偏移
	// (WORD wMid; WORD wPid; UINT vDriverVersion; 共 8 字节)
	pNameOffset = 8

	// szPname (WCHAR[32]) 的字符数
	maxPNameLen = 32
)

// OutputPortNames 枚举本机 MIDI 输出端口名。
// 返回的名称顺序与系统设备 ID 一致, 失败时返回空列表。
func OutputPortNames() ([]string, error) {
	// midiOutGetNumDevs 返回本机 MIDI 输出设备数量
	numDevs, _, _ := procMidiOutGetNumDevs.Call()
	count := int(uint32(numDevs))

	ports := make([]string, 0, count)
	for i := 0; i < count; i++ {
		var caps [midiOutCapsSize]byte
		ret, _, _ := procMidiOutGetDevCapsW.Call(
			uintptr(i),
			uintptr(unsafe.Pointer(&caps[0])),
			uintptr(len(caps)),
		)
		// MMSYSERR_NOERROR == 0, 出错时跳过该设备
		if ret != 0 {
			continue
		}
		p := (*uint16)(unsafe.Pointer(&caps[pNameOffset]))
		name := syscall.UTF16ToString(unsafe.Slice(p, maxPNameLen))
		if name == "" {
			continue
		}
		ports = append(ports, name)
	}
	return ports, nil
}
