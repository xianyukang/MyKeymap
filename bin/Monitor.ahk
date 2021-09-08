   ; ===============================================================================================================================
; AutoHotkey wrapper for Monitor Configuration API Functions
;
; Author ....: jNizM
; Released ..: 2015-05-26
; Modified ..: 2020-07-29
; Github ....: https://github.com/jNizM/Class_Monitor
; Forum .....: https://www.autohotkey.com/boards/viewtopic.php?f=6&t=62955
; ===============================================================================================================================


class Monitor
{

	; ===== PUBLIC METHODS ======================================================================================================

	GetBrightness(Display := "")
	{
		if (hMonitor := this.GetMonitorHandle(Display))
		{
			PhysicalMonitors := this.GetNumberOfPhysicalMonitorsFromHMONITOR(hMonitor)
			hPhysicalMonitor := this.GetPhysicalMonitorsFromHMONITOR(hMonitor, PhysicalMonitors, PHYSICAL_MONITOR)
			Brightness := this.GetMonitorBrightness(hPhysicalMonitor)
			this.DestroyPhysicalMonitors(PhysicalMonitors, PHYSICAL_MONITOR)
			return Brightness
		}
		return false
	}


	GetContrast(Display := "")
	{
		if (hMonitor := this.GetMonitorHandle(Display))
		{
			PhysicalMonitors := this.GetNumberOfPhysicalMonitorsFromHMONITOR(hMonitor)
			hPhysicalMonitor := this.GetPhysicalMonitorsFromHMONITOR(hMonitor, PhysicalMonitors, PHYSICAL_MONITOR)
			Contrast := this.GetMonitorContrast(hPhysicalMonitor)
			this.DestroyPhysicalMonitors(PhysicalMonitors, PHYSICAL_MONITOR)
			return Contrast
		}
		return false
	}


	GetGammaRamp(Display := "")
	{
		if (DisplayName := this.GetDisplayName(Display))
		{
			if (hDC := this.CreateDC(DisplayName))
			{
				GammaRamp := this.GetDeviceGammaRamp(hDC)
				this.DeleteDC(hDC)
				return GammaRamp
			}
			this.DeleteDC(hDC)
		}
		return false
	}


	RestoreFactoryDefault(Display := "")
	{
		if (hMonitor := this.GetMonitorHandle(Display))
		{
			PhysicalMonitors := this.GetNumberOfPhysicalMonitorsFromHMONITOR(hMonitor)
			hPhysicalMonitor := this.GetPhysicalMonitorsFromHMONITOR(hMonitor, PhysicalMonitors, PHYSICAL_MONITOR)
			this.RestoreMonitorFactoryDefaults(hPhysicalMonitor)
			this.DestroyPhysicalMonitors(PhysicalMonitors, PHYSICAL_MONITOR)
			return true
		}
		return false
	}


	SetBrightness(Brightness, Display := "")
	{
		if (hMonitor := this.GetMonitorHandle(Display))
		{
			PhysicalMonitors := this.GetNumberOfPhysicalMonitorsFromHMONITOR(hMonitor)
			hPhysicalMonitor := this.GetPhysicalMonitorsFromHMONITOR(hMonitor, PhysicalMonitors, PHYSICAL_MONITOR)
			GetBrightness    := this.GetMonitorBrightness(hPhysicalMonitor)
			Brightness := (Brightness < GetBrightness["Minimum"]) ? GetBrightness["Minimum"]
						: (Brightness > GetBrightness["Maximum"]) ? GetBrightness["Maximum"]
						: (Brightness)
			this.SetMonitorBrightness(hPhysicalMonitor, Brightness)
			this.DestroyPhysicalMonitors(PhysicalMonitors, PHYSICAL_MONITOR)
			return Brightness
		}
		return false
	}


	SetContrast(Contrast, Display := "")
	{
		if (hMonitor := this.GetMonitorHandle(Display))
		{
			PhysicalMonitors := this.GetNumberOfPhysicalMonitorsFromHMONITOR(hMonitor)
			hPhysicalMonitor := this.GetPhysicalMonitorsFromHMONITOR(hMonitor, PhysicalMonitors, PHYSICAL_MONITOR)
			GetContrast      := this.GetMonitorContrast(hPhysicalMonitor)
			Contrast := (Contrast < GetContrast["Minimum"]) ? GetContrast["Minimum"]
					  : (Contrast > GetContrast["Maximum"]) ? GetContrast["Maximum"]
					  : (Contrast)
			this.SetMonitorContrast(hPhysicalMonitor, Contrast)
			this.DestroyPhysicalMonitors(PhysicalMonitors, PHYSICAL_MONITOR)
			return Contrast
		}
		return false
	}


	SetGammaRamp(Red, Green, Blue, Display := "")
	{
		if (DisplayName := this.GetDisplayName(Display))
		{
			if (hDC := this.CreateDC(DisplayName))
			{
				this.SetDeviceGammaRamp(hDC, Red, Green, Blue)
				this.DeleteDC(hDC)
				return true
			}
			this.DeleteDC(hDC)
		}
		return false
	}
	

	; ===== PRIVATE METHODS =====================================================================================================

	CreateDC(DisplayName)
	{
		if (hDC := DllCall("gdi32\CreateDC", "str", DisplayName, "ptr", 0, "ptr", 0, "ptr", 0, "ptr"))
			return hDC
		return false
	}


	DeleteDC(hDC)
	{
		if (DllCall("gdi32\DeleteDC", "ptr", hDC))
			return true
		return false
	}


	DestroyPhysicalMonitors(PhysicalMonitorArraySize, PHYSICAL_MONITOR)
	{
		if (DllCall("dxva2\DestroyPhysicalMonitors", "uint", PhysicalMonitorArraySize, "ptr", &PHYSICAL_MONITOR))
			return true
		return false
	}


	EnumDisplayMonitors(hMonitor := "")
	{
		static EnumProc := RegisterCallback(Monitor.EnumProc)
		static DisplayMonitors := {}

		if (MonitorNumber = "")
			DisplayMonitors := {}

		if (DisplayMonitors.MaxIndex() = "")
			if (DllCall("user32\EnumDisplayMonitors", "ptr", 0, "ptr", 0, "ptr", EnumProc, "ptr", &DisplayMonitors, "uint"))
				return (MonitorNumber = "") ? DisplayMonitors : DisplayMonitors.HasKey(MonitorNumber) ? DisplayMonitors[MonitorNumber] : false
		return false
	}


	EnumProc(hDC, RECT, ObjectAddr)
	{
		DisplayMonitors := Object(ObjectAddr)
		MonitorInfo := Monitor.GetMonitorInfo(this)
		DisplayMonitors.Push(MonitorInfo)
		return true
	}


	GetDeviceGammaRamp(hMonitor)
	{
		VarSetCapacity(GAMMA_RAMP, 1536, 0)
		if (DllCall("gdi32\GetDeviceGammaRamp", "ptr", hMonitor, "ptr", &GAMMA_RAMP))
		{
			GammaRamp := []
			GammaRamp["Red"]   := NumGet(GAMMA_RAMP,        2, "ushort") - 128
			GammaRamp["Green"] := NumGet(GAMMA_RAMP,  512 + 2, "ushort") - 128
			GammaRamp["Blue"]  := NumGet(GAMMA_RAMP, 1024 + 2, "ushort") - 128
			return GammaRamp
		}
		return false
	}


	GetDisplayName(Display := "")
	{
		DisplayName := ""

		if (Enum := this.EnumDisplayMonitors()) && (Display != "")
		{
			for k, Mon in Enum
				if (InStr(Mon["Name"], Display))
					DisplayName := Mon["Name"]
		}
		if (DisplayName = "")
			if (hMonitor := this.MonitorFromWindow())
				DisplayName := this.GetMonitorInfo(hMonitor)["Name"]

		return DisplayName
	}


	GetMonitorBrightness(hMonitor)
	{
		if (DllCall("dxva2\GetMonitorBrightness", "ptr", hMonitor, "uint*", Minimum, "uint*", Current, "uint*", Maximum))
			return { "Minimum": Minimum, "Current": Current, "Maximum": Maximum }
		return false
	}


	GetMonitorContrast(hMonitor)
	{
		if (DllCall("dxva2\GetMonitorContrast", "ptr", hMonitor, "uint*", Minimum, "uint*", Current, "uint*", Maximum))
			return { "Minimum": Minimum, "Current": Current, "Maximum": Maximum }
		return false
	}


	GetMonitorHandle(Display := "")
	{
		hMonitor := 0

		if (Enum := this.EnumDisplayMonitors()) && (Display != "")
		{
			for k, Mon in Enum
				if (InStr(Mon["Name"], Display))
					hMonitor := Mon["Handle"]
		}
		if !(hMonitor)
			hMonitor := this.MonitorFromWindow()

		return hMonitor
	}


	GetMonitorInfo(hMonitor)
	{
		NumPut(VarSetCapacity(MONITORINFOEX, 40 + (32 << !!A_IsUnicode)), MONITORINFOEX, 0, "uint")
		if (DllCall("user32\GetMonitorInfo", "ptr", hMonitor, "ptr", &MONITORINFOEX))
		{
			MONITORINFO := []
			MONITORINFO["Handle"]   := hMonitor
			MONITORINFO["Name"]     := Name := StrGet(&MONITORINFOEX + 40, 32)
			MONITORINFO["Number"]   := RegExReplace(Name, ".*(\d+)$", "$1")
			MONITORINFO["Left"]     := NumGet(MONITORINFOEX,  4, "int")
			MONITORINFO["Top"]      := NumGet(MONITORINFOEX,  8, "int")
			MONITORINFO["Right"]    := NumGet(MONITORINFOEX, 12, "int")
			MONITORINFO["Bottom"]   := NumGet(MONITORINFOEX, 16, "int")
			MONITORINFO["WALeft"]   := NumGet(MONITORINFOEX, 20, "int")
			MONITORINFO["WATop"]    := NumGet(MONITORINFOEX, 24, "int")
			MONITORINFO["WARight"]  := NumGet(MONITORINFOEX, 28, "int")
			MONITORINFO["WABottom"] := NumGet(MONITORINFOEX, 32, "int")
			MONITORINFO["Primary"]  := NumGet(MONITORINFOEX, 36, "uint")
			return MONITORINFO
		}
		return false
	}


	GetNumberOfPhysicalMonitorsFromHMONITOR(hMonitor)
	{
		if (DllCall("dxva2\GetNumberOfPhysicalMonitorsFromHMONITOR", "ptr", hMonitor, "uint*", NumberOfPhysicalMonitors))
			return NumberOfPhysicalMonitors
		return false
	}


	GetPhysicalMonitorsFromHMONITOR(hMonitor, PhysicalMonitorArraySize, ByRef PHYSICAL_MONITOR)
	{
		VarSetCapacity(PHYSICAL_MONITOR, (A_PtrSize + 256) * PhysicalMonitorArraySize, 0)
		if (DllCall("dxva2\GetPhysicalMonitorsFromHMONITOR", "ptr", hMonitor, "uint", PhysicalMonitorArraySize, "ptr", &PHYSICAL_MONITOR))
			return NumGet(PHYSICAL_MONITOR, 0, "ptr")
		return false
	}


	MonitorFromWindow(hWindow := 0)
	{
		static MONITOR_DEFAULTTOPRIMARY := 0x00000001

		if (hMonitor := DllCall("user32\MonitorFromWindow", "ptr", hWindow, "uint", MONITOR_DEFAULTTOPRIMARY))
			return hMonitor
		return false
	}


	RestoreMonitorFactoryDefaults(hMonitor)
	{
		if (DllCall("dxva2\RestoreMonitorFactoryDefaults", "ptr", hMonitor))
			return false
		return true
	}


	SetDeviceGammaRamp(hMonitor, Red, Green, Blue)
	{
		loop % VarSetCapacity(GAMMA_RAMP, 1536, 0) / 6
		{
			NumPut((r := (red   + 128) * (A_Index - 1)) > 65535 ? 65535 : r, GAMMA_RAMP,        2 * (A_Index - 1), "ushort")
			NumPut((g := (green + 128) * (A_Index - 1)) > 65535 ? 65535 : g, GAMMA_RAMP,  512 + 2 * (A_Index - 1), "ushort")
			NumPut((b := (blue  + 128) * (A_Index - 1)) > 65535 ? 65535 : b, GAMMA_RAMP, 1024 + 2 * (A_Index - 1), "ushort")
		}
		if (DllCall("gdi32\SetDeviceGammaRamp", "ptr", hMonitor, "ptr", &GAMMA_RAMP))
			return true
		return false
	}


	SetMonitorBrightness(hMonitor, Brightness)
	{
		if (DllCall("dxva2\SetMonitorBrightness", "ptr", hMonitor, "uint", Brightness))
			return true
		return false
	}


	SetMonitorContrast(hMonitor, Contrast)
	{
		if (DllCall("dxva2\SetMonitorContrast", "ptr", hMonitor, "uint", Contrast))
			return true
		return false
	}

}

; ===============================================================================================================================