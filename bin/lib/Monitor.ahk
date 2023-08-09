; =================================================================================================== ;
; AutoHotkey V2.0-beta.12 Wrapper for Monitor Configuration WinAPI Functions
;
; Original Author ....: jNizM
; Released ...........: 2015-05-26
; Modified ...........: 2022-10-19
; Improved By ........: tigerlily, CloakerSmoker
; Version ............: 2.4.1
; Github .............: https://github.com/tigerlily-dev/Monitor-Configuration-Class
; Forum ..............: https://www.autohotkey.com/boards/viewtopic.php?f=83&t=79220
; License/Copyright ..: The Unlicense (https://unlicense.org)
;
;
; =================================================================================================== ;


class Monitor {

; ===== PUBLIC METHODS ============================================================================== ;
	
	
	; ===== GET METHODS ===== ;
	
	GetInfo() => this.EnumDisplayMonitors()
	
	GetBrightness(Display := "") => this.GetSetting("GetMonitorBrightness", Display)
	
	GetContrast(Display := "") => this.GetSetting("GetMonitorContrast", Display)
	
	GetGammaRamp(Display := "") => this.GammaSetting("GetDeviceGammaRamp", , , , Display)
	
	GetRedDrive(Display := "") => this.GetSetting("GetMonitorRedDrive", Display)
	
	GetGreenDrive(Display := "") => this.GetSetting("GetMonitorGreenDrive", Display)
	
	GetBlueDrive(Display := "") => this.GetSetting("GetMonitorBlueDrive", Display)
	
	GetRedGain(Display := "") => this.GetSetting("GetMonitorRedGain", Display)
	
	GetGreenGain(Display := "") => this.GetSetting("GetMonitorGreenGain", Display)
	
	GetBlueGain(Display := "") => this.GetSetting("GetMonitorBlueGain", Display)
	
	GetDisplayAreaWidth(Display := "") => this.GetSetting("GetMonitorDisplayAreaWidth", Display)
	
	GetDisplayAreaHeight(Display := "") => this.GetSetting("GetMonitorDisplayAreaHeight", Display)
	
	GetDisplayAreaPositionHorizontal(Display := "") => this.GetSetting("GetMonitorDisplayAreaPositionHorizontal", Display)
	
	GetDisplayAreaPositionVertical(Display := "") => this.GetSetting("GetMonitorDisplayAreaPositionVertical", Display)
	
	GetVCPFeatureAndReply(VCPCode, Display := "") => this.GetSetting("GetVCPFeatureAndVCPFeatureReply", Display, VCPCode)	
	
	GetSharpness(Display := "") => this.GetSetting("GetVCPFeatureAndVCPFeatureReply", Display, 0x87)["Current"]

	CapabilitiesRequestAndCapabilitiesReply(Display := "") => this.GetSetting("MonitorCapabilitiesRequestAndCapabilitiesReply", Display)
	
	GetCapabilitiesStringLength(Display := "") => this.GetSetting("GetMonitorCapabilitiesStringLength", Display)
	
	GetCapabilities(Display := ""){
		
		static MC_CAPS := Map(
		0x00000000, "MC_CAPS_NONE:`nThe monitor does not support any monitor settings.",
		0x00000001, "MC_CAPS_MONITOR_TECHNOLOGY_TYPE:`nThe monitor supports the GetMonitorTechnologyType function.",
		0x00000002, "MC_CAPS_BRIGHTNESS:`nThe monitor supports the GetMonitorBrightness and SetMonitorBrightness functions.",
		0x00000004, "MC_CAPS_CONTRAST:`nThe monitor supports the GetMonitorContrast and SetMonitorContrast functions.",
		0x00000008, "MC_CAPS_COLOR_TEMPERATURE:`nThe monitor supports the GetMonitorColorTemperature and SetMonitorColorTemperature functions.",
		0x00000010, "MC_CAPS_RED_GREEN_BLUE_GAIN:`nThe monitor supports the GetMonitorRedGreenOrBlueGain and SetMonitorRedGreenOrBlueGain functions.",
		0x00000020, "MC_CAPS_RED_GREEN_BLUE_DRIVE:`nThe monitor supports the GetMonitorRedGreenOrBlueDrive and SetMonitorRedGreenOrBlueDrive functions.",
		0x00000040, "MC_CAPS_DEGAUSS:`nThe monitor supports the DegaussMonitor function.",
		0x00000080, "MC_CAPS_DISPLAY_AREA_POSITION:`nThe monitor supports the GetMonitorDisplayAreaPosition and SetMonitorDisplayAreaPosition functions.",
		0x00000100, "MC_CAPS_DISPLAY_AREA_SIZE:`nThe monitor supports the GetMonitorDisplayAreaSize and SetMonitorDisplayAreaSize functions.",
		0x00000200, "MC_CAPS_RESTORE_FACTORY_DEFAULTS:`nThe monitor supports the RestoreMonitorFactoryDefaults function.",
		0x00000400, "MC_CAPS_RESTORE_FACTORY_COLOR_DEFAULTS:`nThe monitor supports the RestoreMonitorFactoryColorDefaults function.",
		0x00001000, "MC_RESTORE_FACTORY_DEFAULTS_ENABLES_MONITOR_SETTINGS:`nIf this flag is present, calling the RestoreMonitorFactoryDefaults function enables all of the monitor settings used by the high-level monitor configuration functions. For more information, see the Remarks section in RestoreMonitorFactoryDefaults. (https://docs.microsoft.com/en-us/windows/win32/api/highlevelmonitorconfigurationapi/nf-highlevelmonitorconfigurationapi-restoremonitorfactorydefaults)")
		
		if (CapabilitiesFlags := this.GetSetting("GetMonitorCapabilities", Display)["MonitorCapabilities"]){	
			SupportedCapabilities := []
			for FlagValue, FlagDescription in MC_CAPS
				if (CapabilitiesFlags & FlagValue)
					SupportedCapabilities.Push(FlagDescription)
			return SupportedCapabilities
		}	
		throw Error(MC_CAPS[CapabilitiesFlags])
	}	
	
	GetSupportedColorTemperatures(Display := ""){
		
		static MC_SUPPORTED_COLOR_TEMPERATURE := Map(
		0x00000000, "No color temperatures are supported.",
		0x00000001, "The monitor supports 4,000 kelvins (K) color temperature.",
		0x00000002, "The monitor supports 5,000 K color temperature.",
		0x00000004, "The monitor supports 6,500 K color temperature.",
		0x00000008, "The monitor supports 7,500 K color temperature.",
		0x00000010, "The monitor supports 8,200 K color temperature.",
		0x00000020, "The monitor supports 9,300 K color temperature.",
		0x00000040, "The monitor supports 10,000 K color temperature.",
		0x00000080, "The monitor supports 11,500 K color temperature.")
		
		if (ColorTemperatureFlags := this.GetSetting("GetMonitorCapabilities", Display)["SupportedColorTemperatures"]){		
			SupportedColorTemperatures := []
			for FlagValue, FlagDescription in MC_SUPPORTED_COLOR_TEMPERATURE
				if (ColorTemperatureFlags & FlagValue)
					SupportedColorTemperatures.Push(FlagDescription)
			return SupportedColorTemperatures
		}
		throw Error(MC_SUPPORTED_COLOR_TEMPERATURE[ColorTemperatureFlags]) 
	}	
	
	GetColorTemperature(Display := ""){
		
		static MC_COLOR_TEMPERATURE := Map(
		0x00000000,  "Unknown temperature.",
		0x00000001,  "4,000 kelvins (K).",
		0x00000002,  "5,000 kelvins (K).",
		0x00000004,  "6,500 kelvins (K).",
		0x00000008,  "7,500 kelvins (K).",
		0x00000010,  "8,200 kelvins (K).",
		0x00000020,  "9,300 kelvins (K).",
		0x00000040, "10,000 kelvins (K).",
		0x00000080, "11,500 kelvins (K).")
		
		return MC_COLOR_TEMPERATURE[this.GetSetting("GetMonitorColorTemperature", Display)]
	}
	
	GetTechnologyType(Display := ""){
		
		static DISPLAY_TECHNOLOGY_TYPE := Map(
		0x00000000, "Shadow-mask cathode ray tube (CRT)",
		0x00000001, "Aperture-grill CRT",
		0x00000002, "Thin-film transistor (TFT) display",
		0x00000004, "Liquid crystal on silicon (LCOS) display",
		0x00000008, "Plasma display",
		0x00000010, "Organic light emitting diode (LED) display",
		0x00000020, "Electroluminescent display",
		0x00000040, "Microelectromechanical display",
		0x00000080, "Field emission device (FED) display")
		
		return DISPLAY_TECHNOLOGY_TYPE[this.GetSetting("GetMonitorTechnologyType", Display)]	
	}	

		GetPowerMode(Display := ""){
		
		static PowerModes := Map(
		0x01, "On"      , 
		0x02, "Standby" , 
		0x03, "Suspend" , 
		0x04, "Off"     ,
		0x05, "PowerOff")
		
		return PowerModes[this.GetSetting("GetVCPFeatureAndVCPFeatureReply", Display, 0xD6)["Current"]]
	}
	

	; ===== SET METHODS ===== ;
	
	SetBrightness(Brightness, Display := "") => this.SetSetting("SetMonitorBrightness", Brightness, Display)
	
	SetContrast(Contrast, Display := "") => this.SetSetting("SetMonitorContrast", Contrast, Display)
	
	SetGammaRamp(Red := 100, Green := 100, Blue := 100, Display := "") => this.GammaSetting("SetDeviceGammaRamp", Red, Green, Blue, Display)
	
	SetRedDrive(RedDrive, Display := "") => this.SetSetting("SetMonitorRedDrive", RedDrive, Display)
	
	SetGreenDrive(GreenDrive, Display := "") => this.SetSetting("SetMonitorGreenDrive", GreenDrive, Display)
	
	SetBlueDrive(BlueDrive, Display := "") => this.SetSetting("SetMonitorBlueDrive", BlueDrive, Display)
	
	SetRedGain(RedGain, Display := "") => this.SetSetting("SetMonitorRedGain", RedGain, Display)
	
	SetGreenGain(GreenGain, Display := "") => this.SetSetting("SetMonitorGreenGain", GreenGain, Display)
	
	SetBlueGain(BlueGain, Display := "") => this.SetSetting("SetMonitorBlueGain", BlueGain, Display)
	
	SetDisplayAreaWidth(DisplayAreaWidth, Display := "") => this.SetSetting("SetMonitorDisplayAreaWidth", DisplayAreaWidth, Display)
	
	SetDisplayAreaHeight(DisplayAreaHeight, Display := "") => this.SetSetting("SetMonitorDisplayAreaHeight", DisplayAreaHeight, Display)
	
	SetDisplayAreaPositionHorizontal(DisplayAreaPositionHorizontal, Display := "") => this.SetSetting("SetMonitorDisplayAreaPositionHorizontal", DisplayAreaPositionHorizontal, Display)
	
	SetDisplayAreaPositionVertical(DisplayAreaPositionVertical, Display := "") => this.SetSetting("SetMonitorDisplayAreaPositionVertical", DisplayAreaPositionVertical, Display)	
	
	SetVCPFeature(VCPCode, NewValue, Display := "") => this.SetSetting("SetMonitorVCPFeature", VCPCode, Display, NewValue)	
	
	SetSharpness(Sharpness, Display := "") => this.SetSetting("SetMonitorVCPFeature", 0x87, Display, Sharpness)

	SetColorTemperature(ColorTemperature, Display := ""){		
		
		static MC_COLOR_TEMPERATURE := Map(
		0x00000000,  "Unknown temperature.",
		0x00000001,  "4,000 kelvins (K).",
		0x00000002,  "5,000 kelvins (K).",
		0x00000004,  "6,500 kelvins (K).",
		0x00000008,  "7,500 kelvins (K).",
		0x00000010,  "8,200 kelvins (K).",
		0x00000020,  "9,300 kelvins (K).",
		0x00000040, "10,000 kelvins (K).",
		0x00000080, "11,500 kelvins (K).")		
		
		return MC_COLOR_TEMPERATURE[this.SetSetting("SetMonitorColorTemperature", ColorTemperature, Display)]
	}	
	
	SetPowerMode(PowerMode, Display := ""){
	
		static PowerModes := Map(
		"On"   	  , 0x01, 
		"Standby" , 0x02,
		"Suspend" , 0x03, 
		"Off"	  , 0x04, 
		"PowerOff", 0x05)
		
		if (PowerModes.Has(PowerMode))
			if (this.SetSetting("SetMonitorVCPFeature", 0xD6, Display, PowerModes[PowerMode]))
				return PowerMode
		throw Error("An invalid [PowerMode] parameter was passed to the SetPowerMode() Method.")
	}		

	; ===== VOID METHODS ===== ;
	
	Degauss(Display := "") => this.VoidSetting("DegaussMonitor", Display)
	
	RestoreFactoryDefaults(Display := "") => this.VoidSetting("RestoreMonitorFactoryDefaults", Display)
	
	RestoreFactoryColorDefaults(Display := "") => this.VoidSetting("RestoreMonitorFactoryColorDefaults", Display)
	
	SaveCurrentSettings(Display := "") => this.VoidSetting("SaveCurrentMonitorSettings", Display)
	
	
; ===== PRIVATE METHODS ============================================================================= ;
	
	
	; ===== CORE MONITOR METHODS ===== ;
	
	EnumDisplayMonitors(hMonitor := ""){
			    
		static EnumProc := CallbackCreate(Monitor.GetMethod("MonitorEnumProc").Bind(Monitor),, 4)
		static DisplayMonitors := []
		
		if (!DisplayMonitors.Length)
			if !(DllCall("user32\EnumDisplayMonitors", "ptr", 0, "ptr", 0, "ptr", EnumProc, "ptr", ObjPtrAddRef(DisplayMonitors), "uint"))
				return false
		return DisplayMonitors    
	}
	
	static MonitorEnumProc(hMonitor, hDC, pRECT, ObjectAddr){

		DisplayMonitors := ObjFromPtrAddRef(ObjectAddr)
		MonitorData := Monitor.GetMonitorInfo(hMonitor)
		DisplayMonitors.Push(MonitorData)
		return true
	}
	
	static GetMonitorInfo(hMonitor){ ; (MONITORINFO = 40 byte struct) + (MONITORINFOEX = 64 bytes)
	
		NumPut("uint", 104, MONITORINFOEX := Buffer(104))
		if (DllCall("user32\GetMonitorInfo", "ptr", hMonitor, "ptr", MONITORINFOEX)){
			MONITORINFO := Map()
			MONITORINFO["Handle"]   := hMonitor
			MONITORINFO["Name"]     := Name := StrGet(MONITORINFOEX.Ptr + 40, 32)
			MONITORINFO["Number"]   := RegExReplace(Name, ".*(\d+)$", "$1")
			MONITORINFO["Left"]     := NumGet(MONITORINFOEX,  4, "int")
			MONITORINFO["Top"]      := NumGet(MONITORINFOEX,  8, "int")
			MONITORINFO["Right"]    := NumGet(MONITORINFOEX, 12, "int")
			MONITORINFO["Bottom"]   := NumGet(MONITORINFOEX, 16, "int")
			MONITORINFO["WALeft"]   := NumGet(MONITORINFOEX, 20, "int")
			MONITORINFO["WATop"]    := NumGet(MONITORINFOEX, 24, "int")
			MONITORINFO["WARight"]  := NumGet(MONITORINFOEX, 28, "int")
			MONITORINFO["WABottom"] := NumGet(MONITORINFOEX, 32, "int")
			MONITORINFO["Primary"]  := NumGet(MONITORINFOEX, 36,"uint")
			return MONITORINFO
		}
		throw Error("GetMonitorInfo: " A_LastError, -1)
	}
		
	GetMonitorHandle(Display := "", hMonitor := 0, hWindow := 0){

		MonitorInfo := this.EnumDisplayMonitors()
		if (Display != ""){
			for Info in MonitorInfo {
				if (InStr(Info["Name"], Display)){
					hMonitor := Info["Handle"]
					break
				}
			}
		}

		if (!hMonitor)
			hMonitor := DllCall("user32\MonitorFromWindow", "ptr", hWindow, "uint", 0x00000002) ; MONITOR_DEFAULTTONEAREST = 0x00000002
		return hMonitor
	}
	
	GetNumberOfPhysicalMonitorsFromHMONITOR(hMonitor, NumberOfPhysicalMonitors := 0){

		if (DllCall("dxva2\GetNumberOfPhysicalMonitorsFromHMONITOR", "ptr", hMonitor, "uint*", &NumberOfPhysicalMonitors))
			return NumberOfPhysicalMonitors
		return false
	}
	
	GetPhysicalMonitorsFromHMONITOR(hMonitor, PhysicalMonitorArraySize, &PHYSICAL_MONITOR){
        
		PHYSICAL_MONITOR := Buffer((A_PtrSize + 256) * PhysicalMonitorArraySize)
		if (DllCall("dxva2\GetPhysicalMonitorsFromHMONITOR", "ptr", hMonitor, "uint", PhysicalMonitorArraySize, "ptr", PHYSICAL_MONITOR))
			return NumGet(PHYSICAL_MONITOR, 0, "ptr")
		return false
	}
	
	DestroyPhysicalMonitors(PhysicalMonitorArraySize, &PHYSICAL_MONITOR){

		if (DllCall("dxva2\DestroyPhysicalMonitors", "uint", PhysicalMonitorArraySize, "ptr", PHYSICAL_MONITOR))
			return true
		return false
	}
	
	CreateDC(DisplayName){

		if (hDC := DllCall("gdi32\CreateDC", "str", DisplayName, "ptr", 0, "ptr", 0, "ptr", 0, "ptr"))
			return hDC
		return false
	}
	
	DeleteDC(hDC){

		if (DllCall("gdi32\DeleteDC", "ptr", hDC))
			return true
		return false
	}
	
	
	; ===== HELPER METHODS ===== ;
	
	GetSetting(GetMethodName, Display := "", params*){

		if (hMonitor := this.GetMonitorHandle(Display)){
			PHYSICAL_MONITOR := ""
			PhysicalMonitors := this.GetNumberOfPhysicalMonitorsFromHMONITOR(hMonitor)
			hPhysicalMonitor := this.GetPhysicalMonitorsFromHMONITOR(hMonitor, PhysicalMonitors, &PHYSICAL_MONITOR)
			Setting := this.%GetMethodName%(hPhysicalMonitor, params*)
			this.DestroyPhysicalMonitors(PhysicalMonitors, &PHYSICAL_MONITOR)
			return Setting
		}
		throw Error("Unable to get handle to monitor.`n`nError code: " Format("0x{:X}", A_LastError))
	}
	
	SetSetting(SetMethodName, Setting, Display := "", params*){

		if (hMonitor := this.GetMonitorHandle(Display)){	
			PHYSICAL_MONITOR := ""		
			PhysicalMonitors := this.GetNumberOfPhysicalMonitorsFromHMONITOR(hMonitor)
			hPhysicalMonitor := this.GetPhysicalMonitorsFromHMONITOR(hMonitor, PhysicalMonitors, &PHYSICAL_MONITOR)

			if (SetMethodName = "SetMonitorVCPFeature" || SetMethodName = "SetMonitorColorTemperature"){				
				Setting := this.%SetMethodName%(hPhysicalMonitor, Setting, params*)
				this.DestroyPhysicalMonitors(PhysicalMonitors, &PHYSICAL_MONITOR)
				return Setting				
			}
			else {	
				GetMethodName := RegExReplace(SetMethodName, "S(.*)", "G$1")
				GetSetting := this.%GetMethodName%(hPhysicalMonitor)
				Setting := (Setting < GetSetting["Minimum"]) ? GetSetting["Minimum"]
					    :  (Setting > GetSetting["Maximum"]) ? GetSetting["Maximum"]
					    :  (Setting)
				this.%SetMethodName%(hPhysicalMonitor, Setting)
				this.DestroyPhysicalMonitors(PhysicalMonitors, &PHYSICAL_MONITOR)
				return Setting
			}
		
		} 
		throw Error("Unable to get handle to monitor.`n`nError code: " Format("0x{:X}", A_LastError))
	}
	
	VoidSetting(VoidMethodName, Display := ""){        

		if (hMonitor := this.GetMonitorHandle(Display)){
			PHYSICAL_MONITOR := ""
			PhysicalMonitors := this.GetNumberOfPhysicalMonitorsFromHMONITOR(hMonitor)
			hPhysicalMonitor := this.GetPhysicalMonitorsFromHMONITOR(hMonitor, PhysicalMonitors, &PHYSICAL_MONITOR)
			bool := this.%VoidMethodName%(hPhysicalMonitor)
			this.DestroyPhysicalMonitors(PhysicalMonitors, &PHYSICAL_MONITOR)
			return bool
		}
		throw Error("Unable to get handle to monitor.`n`nError code: " Format("0x{:X}", A_LastError))
	}
	
	GammaSetting(GammaMethodName, Red := "", Green := "", Blue := "", Display := ""){
    
		MonitorInfo := this.EnumDisplayMonitors() ; might be able to find a better way to write this if-else code section below

		if (!Display){                      ; if no display # is passed, default to primary
		    for Info in MonitorInfo {                                               
			if (Info["Primary"]){                                  
			    Display := A_Index                                 
			    break                                              
			}                                                                                 
		    }          
		}
		else if (!IsNumber(Display)){       ; if a display name is passed, determine which display # belongs to it
		    for Info in MonitorInfo {                                   
			if (MonitorInfo[A_Index]["Name"] = Display){           
			    Display := A_Index                                 
			    break                                              
			}       
		    }
		}

		if (Display > MonitorInfo.Length){  ; if an invalid monitor # is passed, default to primary monitor #             
		    for Info in MonitorInfo {                                               
			if (Info["Primary"]){                                  
			    Display := A_Index                                 
			    break                                              
			}                                                                                 
		    }          
		}                    

		if (hDC := this.CreateDC(MonitorInfo[Display]["Name"])){	
		    if (GammaMethodName = "SetDeviceGammaRamp"){
			for Color in ["Red", "Green", "Blue"]{
			    %Color% := (%Color% <    0)	?    0  ; ensure values passed are within the valid ranges
				    :  (%Color% >  100) ?  100
				    :  (%Color%)	
			    %Color% := Round((2.56 * %Color%) - 128, 1) ; convert RGB values to decimal	(function-compatible)
			}			
			this.SetDeviceGammaRamp(hDC, Red, Green, Blue)
			this.DeleteDC(hDC)

			for Color in ["Red", "Green", "Blue"]
			    %Color% := Round((%Color% + 128) / 2.56, 1) ; convert RBG values back to percentage	(human-readable)

			return Map("Red", Red, "Green", Green, "Blue", Blue)
		    }
		    else { ; if (GammaMethodName = "GetDeviceGammaRamp")
			GammaRamp := this.GetDeviceGammaRamp(hDC)	
			for Color, GammaLevel in GammaRamp		
			    GammaRamp[Color] := Round((GammaLevel + 128) / 2.56, 1) ; convert RGB values to percentage (human-readable)
			this.DeleteDC(hDC)
			return GammaRamp
		    }			

		}
		this.DeleteDC(hDC)
		throw Error("Unable to get handle to Device Context.`n`nError code: " Format("0x{:X}", A_LastError))	
	}
	
	; ===== GET METHODS ===== ;
	
	GetMonitorBrightness(hMonitor, Minimum := 0, Current := 0, Maximum := 0){
       
		if (DllCall("dxva2\GetMonitorBrightness", "ptr", hMonitor, "uint*", &Minimum, "uint*", &Current, "uint*", &Maximum))
			return Map("Minimum", Minimum, "Current", Current, "Maximum", Maximum)
		throw Error("Unable to retreive values.`n`nError code: " Format("0x{:X}", A_LastError))
	}
	
	GetMonitorContrast(hMonitor, Minimum := 0, Current := 0, Maximum := 0){

		if (DllCall("dxva2\GetMonitorContrast", "ptr", hMonitor, "uint*", &Minimum, "uint*", &Current, "uint*", &Maximum))
			return Map("Minimum", Minimum, "Current", Current, "Maximum", Maximum)
		throw Error("Unable to retreive values.`n`nError code: " Format("0x{:X}", A_LastError))
	}
	
	GetDeviceGammaRamp(hMonitor){
					
		if (DllCall("gdi32\GetDeviceGammaRamp", "ptr", hMonitor, "ptr", GAMMA_RAMP := Buffer(1536)))
			return Map(
			"Red"  , NumGet(GAMMA_RAMP.Ptr,        2, "ushort") - 128,
			"Green", NumGet(GAMMA_RAMP.Ptr,  512 + 2, "ushort") - 128,
			"Blue" , NumGet(GAMMA_RAMP.Ptr, 1024 + 2, "ushort") - 128)
		throw Error("Unable to retreive values.`n`nError code: " Format("0x{:X}", A_LastError))
	}
	
	GetMonitorRedDrive(hMonitor, Minimum := 0, Current := 0, Maximum := 0){ ;	MC_RED_DRIVE = 0x00000000
		
		if (DllCall("dxva2\GetMonitorRedGreenOrBlueDrive", "ptr", hMonitor, "ptr", 0x00000000, "uint*", &Minimum, "uint*", &Current, "uint*", &Maximum))
			return Map("Minimum", Minimum, "Current", Current, "Maximum", Maximum)
		throw Error("Unable to retreive values.`n`nError code: " Format("0x{:X}", A_LastError))
	}
	
	GetMonitorGreenDrive(hMonitor, Minimum := 0, Current := 0, Maximum := 0){ ;	MC_GREEN_DRIVE = 0x00000001
		
		if (DllCall("dxva2\GetMonitorRedGreenOrBlueDrive", "ptr", hMonitor, "ptr", 0x00000001, "uint*", &Minimum, "uint*", &Current, "uint*", &Maximum))
			return Map("Minimum", Minimum, "Current", Current, "Maximum", Maximum)
		throw Error("Unable to retreive values.`n`nError code: " Format("0x{:X}", A_LastError))
	}
	
	GetMonitorBlueDrive(hMonitor, Minimum := 0, Current := 0, Maximum := 0){ ;	MC_BLUE_DRIVE = 0x00000002
		
		if (DllCall("dxva2\GetMonitorRedGreenOrBlueDrive", "ptr", hMonitor, "ptr", 0x00000002, "uint*", &Minimum, "uint*", &Current, "uint*", &Maximum))
			return Map("Minimum", Minimum, "Current", Current, "Maximum", Maximum)
		MsgBox "Failed"
		throw Error("Unable to retreive values.`n`nError code: " Format("0x{:X}", A_LastError))
	}
	
	GetMonitorRedGain(hMonitor, Minimum := 0, Current := 0, Maximum := 0){ ;	MC_RED_GAIN = 0x00000000
		
		if (DllCall("dxva2\GetMonitorRedGreenOrBlueGain", "ptr", hMonitor, "ptr", 0x00000000, "uint*", &Minimum, "uint*", &Current, "uint*", &Maximum))
			return Map("Minimum", Minimum, "Current", Current, "Maximum", Maximum)
		throw Error("Unable to retreive values.`n`nError code: " Format("0x{:X}", A_LastError))
	}
	
	GetMonitorGreenGain(hMonitor, Minimum := 0, Current := 0, Maximum := 0){ ;	MC_GREEN_GAIN = 0x00000001
		
		if (DllCall("dxva2\GetMonitorRedGreenOrBlueGain", "ptr", hMonitor, "ptr", 0x00000001, "uint*", &Minimum, "uint*", &Current, "uint*", &Maximum))
			return Map("Minimum", Minimum, "Current", Current, "Maximum", Maximum)
		throw Error("Unable to retreive values.`n`nError code: " Format("0x{:X}", A_LastError))
	}
	
	GetMonitorBlueGain(hMonitor, Minimum := 0, Current := 0, Maximum := 0){ ;	MC_BLUE_GAIN = 0x00000002
	
		if (DllCall("dxva2\GetMonitorRedGreenOrBlueGain", "ptr", hMonitor, "ptr", 0x00000002, "uint*", &Minimum, "uint*", &Current, "uint*", &Maximum))
			return Map("Minimum", Minimum, "Current", Current, "Maximum", Maximum)
		throw Error("Unable to retreive values.`n`nError code: " Format("0x{:X}", A_LastError))
	}	
	
	GetMonitorDisplayAreaWidth(hMonitor, Minimum := 0, Current := 0, Maximum := 0){ ;	MC_WIDTH = 0x00000000
		
		if (DllCall("dxva2\GetMonitorDisplayAreaSize", "ptr", hMonitor, "ptr", 0x00000000, "uint*", &Minimum, "uint*", &Current, "uint*", &Maximum))
			return Map("Minimum", Minimum, "Current", Current, "Maximum", Maximum)
		throw Error("Unable to retreive values.`n`nError code: " Format("0x{:X}", A_LastError))
	}
	
	GetMonitorDisplayAreaHeight(hMonitor, Minimum := 0, Current := 0, Maximum := 0){ ;	MC_HEIGHT = 0x00000001
	
		if (DllCall("dxva2\GetMonitorDisplayAreaSize", "ptr", hMonitor, "ptr", 0x00000001, "uint*", &Minimum, "uint*", &Current, "uint*", &Maximum))
			return Map("Minimum", Minimum, "Current", Current, "Maximum", Maximum)
		throw Error("Unable to retreive values.`n`nError code: " Format("0x{:X}", A_LastError))
	}
	
	GetMonitorDisplayAreaPositionHorizontal(hMonitor, Minimum := 0, Current := 0, Maximum := 0){ ;	MC_HORIZONTAL_POSITION = 0x00000000
		
		if (DllCall("dxva2\GetMonitorDisplayAreaPosition", "ptr", hMonitor, "ptr", 0x00000000, "uint*", &Minimum, "uint*", &Current, "uint*", &Maximum))
			return Map("Minimum", Minimum, "Current", Current, "Maximum", Maximum)
		throw Error("Unable to retreive values.`n`nError code: " Format("0x{:X}", A_LastError))
	}
	
	GetMonitorDisplayAreaPositionVertical(hMonitor, Minimum := 0, Current := 0, Maximum := 0){ ;	MC_VERTICAL_POSITION = 0x00000001
		
		if (DllCall("dxva2\GetMonitorDisplayAreaPosition", "ptr", hMonitor, "ptr", 0x00000001, "uint*", &Minimum, "uint*", &Current, "uint*", &Maximum))
			return Map("Minimum", Minimum, "Current", Current, "Maximum", Maximum)
		throw Error("Unable to retreive values.`n`nError code: " Format("0x{:X}", A_LastError))
	}	
	
	GetVCPFeatureAndVCPFeatureReply(hMonitor, VCPCode, vct := 0, currentRefue := 0, MaximumValue := 0){

		static VCP_CODE_TYPE := Map(
					0x00000000, "MC_MOMENTARY — Momentary VCP code. Sending a command of this type causes the monitor to initiate a self-timed operation and then revert to its original state. Examples include display tests and degaussing.",
					0x00000001, "MC_SET_PARAMETER — Set Parameter VCP code. Sending a command of this type changes some aspect of the monitor's operation.")
		
		if (DllCall("dxva2\GetVCPFeatureAndVCPFeatureReply", "ptr", hMonitor, "ptr", VCPCode, "uint*", vct, "uint*", &currentRefue, "uint*", &MaximumValue))
			return Map("VCPCode"    ,  Format("0x{:X}", VCPCode),
					   "VCPCodeType",  VCP_CODE_TYPE[vct], 
					   "Current"	,  currentRefue, 
					   "Maximum"	, (MaximumValue ? MaximumValue : "Undefined due to non-continuous (NC) VCP Code."))
		throw Error("Unable to retreive values.`n`nError code: " Format("0x{:X}", A_LastError))
	}
	
	GetMonitorCapabilitiesStringLength(hMonitor, CapabilitiesStrLen := 0){

		if (DllCall("dxva2\GetCapabilitiesStringLength", "ptr", hMonitor, "uint*", &CapabilitiesStrLen))
			return CapabilitiesStrLen
		throw Error("Unable to retreive values.`n`nError code: " Format("0x{:X}", A_LastError))
	}
	
	MonitorCapabilitiesRequestAndCapabilitiesReply(hMonitor, ASCIICapabilitiesString := "", CapabilitiesStrLen := 0){

        	if (CapabilitiesStrLen := this.GetMonitorCapabilitiesStringLength(hMonitor)){
        		ASCIICapabilitiesString := Buffer(CapabilitiesStrLen)
		    	if (DllCall("dxva2\GetCapabilitiesStringLength", "ptr", hMonitor, "ptr", ASCIICapabilitiesString.Ptr, "uint", CapabilitiesStrLen))
                		return ASCIICapabilitiesString			
        	}
        	throw Error("Unable to retreive value.`n`nError code: " Format("0x{:X}", A_LastError))
	}	
	
	GetMonitorCapabilities(hMonitor, MonitorCapabilities := 0, SupportedColorTemperatures := 0){

		if (DllCall("dxva2\GetMonitorCapabilities", "ptr", hMonitor, "uint*", &MonitorCapabilities, "uint*", &SupportedColorTemperatures))
			return Map("MonitorCapabilities"	   , MonitorCapabilities, 
				  	   "SupportedColorTemperatures", SupportedColorTemperatures)		
		throw Error("Unable to retreive values.`n`nError code: " Format("0x{:X}", A_LastError))
	}
	
	GetMonitorColorTemperature(hMonitor, CurrentColorTemperature := 0){

		if (DllCall("dxva2\GetMonitorColorTemperature", "ptr", hMonitor, "uint*", CurrentColorTemperature))
			return CurrentColorTemperature
		throw Error("Unable to retreive value.`n`nError code: " Format("0x{:X}", A_LastError))
	}
	
	GetMonitorTechnologyType(hMonitor, DisplayTechnologyType := 0){

		if (DllCall("dxva2\GetMonitorTechnologyType", "ptr", hMonitor, "uint*", &DisplayTechnologyType))
			return DisplayTechnologyType
		throw Error("Unable to retreive value.`n`nError code: " Format("0x{:X}", A_LastError))
	}
	
	
	; ===== SET METHODS ===== ;
	
	SetMonitorBrightness(hMonitor, Brightness){

		if (DllCall("dxva2\SetMonitorBrightness", "ptr", hMonitor, "uint", Brightness))
			return Brightness
		throw Error("Unable to set value.`n`nError code: " Format("0x{:X}", A_LastError))
	}
	
	SetMonitorContrast(hMonitor, Contrast){

		if (DllCall("dxva2\SetMonitorContrast", "ptr", hMonitor, "uint", Contrast))
			return Contrast
		throw Error("Unable to set value.`n`nError code: " Format("0x{:X}", A_LastError))
	}
	
	SetDeviceGammaRamp(hMonitor, red, green, blue){

        GAMMA_RAMP := Buffer(1536)
		while ((i := A_Index - 1) < 256 ){	
			NumPut("ushort", (r := (red   + 128) * i) > 65535 ? 65535 : r, GAMMA_RAMP,        2 * i)
			NumPut("ushort", (g := (green + 128) * i) > 65535 ? 65535 : g, GAMMA_RAMP,  512 + 2 * i)
			NumPut("ushort", (b := (blue  + 128) * i) > 65535 ? 65535 : b, GAMMA_RAMP, 1024 + 2 * i)
		}
		if (DllCall("gdi32\SetDeviceGammaRamp", "ptr", hMonitor, "ptr", GAMMA_RAMP))
			return true
		throw Error("Unable to set values.`n`nError code: " Format("0x{:X}", A_LastError))
	}	
	
	SetMonitorRedDrive(hMonitor, RedDrive){ ;	MC_RED_DRIVE = 0x00000000
		
		if (DllCall("dxva2\SetMonitorRedGreenOrBlueDrive", "ptr", hMonitor, "ptr", 0x00000000, "uint", RedDrive))
			return true
		throw Error("Unable to set value.`n`nError code: " Format("0x{:X}", A_LastError))
	}
	
	SetMonitorGreenDrive(hMonitor, GreenDrive){ ;	MC_GREEN_DRIVE = 0x00000001
		
		if (DllCall("dxva2\SetMonitorRedGreenOrBlueDrive", "ptr", hMonitor, "ptr", 0x00000001, "uint", GreenDrive))
			return true
		throw Error("Unable to set value.`n`nError code: " Format("0x{:X}", A_LastError))
	}
	
	SetMonitorBlueDrive(hMonitor, BlueDrive){ ;	MC_BLUE_DRIVE = 0x00000002
		
		if (DllCall("dxva2\SetMonitorRedGreenOrBlueDrive", "ptr", hMonitor, "ptr", 0x00000002, "uint", BlueDrive))
			return true
		throw Error("Unable to set value.`n`nError code: " Format("0x{:X}", A_LastError))
	}
	
	SetMonitorRedGain(hMonitor, RedGain){ ;	MC_RED_GAIN = 0x00000000
		
		if (DllCall("dxva2\SetMonitorRedGreenOrBlueGain", "ptr", hMonitor, "ptr", 0x00000000, "uint", RedGain))
			return true
		throw Error("Unable to set value.`n`nError code: " Format("0x{:X}", A_LastError))
	}
	
	SetMonitorGreenGain(hMonitor, GreenGain){ ;	MC_GREEN_GAIN = 0x00000001
		
		if (DllCall("dxva2\SetMonitorRedGreenOrBlueGain", "ptr", hMonitor, "ptr", 0x00000001, "uint", GreenGain))
			return true
		throw Error("Unable to set value.`n`nError code: " Format("0x{:X}", A_LastError))
	}
	
	SetMonitorBlueGain(hMonitor, BlueGain){ ;	MC_BLUE_GAIN = 0x00000002
		
		if (DllCall("dxva2\SetMonitorRedGreenOrBlueGain", "ptr", hMonitor, "ptr", 0x00000002, "uint", BlueGain))
			return true
		throw Error("Unable to set value.`n`nError code: " Format("0x{:X}", A_LastError))
	}		
	
	SetMonitorDisplayAreaWidth(hMonitor, DisplayAreaWidth){ ;	MC_WIDTH = 0x00000000
		 
		if (DllCall("dxva2\SetMonitorDisplayAreaSize", "ptr", hMonitor, "ptr", 0x00000000, "uint", DisplayAreaWidth))
			return true
		throw Error("Unable to set value.`n`nError code: " Format("0x{:X}", A_LastError))
	}
	
	SetMonitorDisplayAreaHeight(hMonitor, DisplayAreaHeight){ ;	MC_HEIGHT = 0x00000001
		
		if (DllCall("dxva2\SetMonitorDisplayAreaSize", "ptr", hMonitor, "ptr", 0x00000001, "uint", DisplayAreaHeight))
			return true
		throw Error("Unable to set value.`n`nError code: " Format("0x{:X}", A_LastError))
	}
	
	SetMonitorDisplayAreaPositionHorizontal(hMonitor, NewHorizontalPosition){ ;	MC_HORIZONTAL_POSITION = 0x00000000
		 
		if (DllCall("dxva2\SetMonitorDisplayAreaPosition", "ptr", hMonitor, "ptr", 0x00000000, "uint", NewHorizontalPosition))
			return true
		throw Error("Unable to set value.`n`nError code: " Format("0x{:X}", A_LastError))
	}	
	
	SetMonitorDisplayAreaPositionVertical(hMonitor, NewVerticalPosition){ ;	MC_VERTICAL_POSITION = 0x00000001
		
		if (DllCall("dxva2\SetMonitorDisplayAreaPosition", "ptr", hMonitor, "ptr", 0x00000001, "uint", NewVerticalPosition))
			return true
		throw Error("Unable to set value.`n`nError code: " Format("0x{:X}", A_LastError))
	}	
	
	SetMonitorVCPFeature(hMonitor, VCPCode, NewValue){

		if (DllCall("dxva2\SetVCPFeature", "ptr", hMonitor, "ptr", VCPCode, "uint", NewValue))
			return Map("VCPCode", Format("0x{:X}", VCPCode), "NewValue", NewValue)
		throw Error("Unable to set value.`n`nError code: " Format("0x{:X}", A_LastError))
	}		
	
	SetMonitorColorTemperature(hMonitor, CurrentColorTemperature){

		if (DllCall("dxva2\SetMonitorColorTemperature", "ptr", hMonitor, "uint", CurrentColorTemperature))
			return CurrentColorTemperature
		throw Error("Unable to set value.`n`nError code: " Format("0x{:X}", A_LastError))
	}
	
	
	; ===== VOID METHODS ===== ;
	
	DegaussMonitor(hMonitor){

		if (DllCall("dxva2\DegaussMonitor", "ptr", hMonitor))
			return true
		throw Error("Unable to degauss monitor.`n`nError code: " Format("0x{:X}", A_LastError))
	}
	
	RestoreMonitorFactoryDefaults(hMonitor){

		if (DllCall("dxva2\RestoreMonitorFactoryDefaults", "ptr", hMonitor))
			return true
		throw Error("Unable to restore monitor to factory defaults.`n`nError code: " Format("0x{:X}", A_LastError))
	}
	
	RestoreMonitorFactoryColorDefaults(hMonitor){

		if (DllCall("dxva2\RestoreMonitorFactoryColorDefaults", "ptr", hMonitor))
			return true
		throw Error("Unable to restore monitor to factory color defaults.`n`nError code: " Format("0x{:X}", A_LastError))
	}
	
	SaveCurrentMonitorSettings(hMonitor){

		if (DllCall("dxva2\RestoreMonitorFactoryDefaults", "ptr", hMonitor))
			return true
		throw Error("Unable to save current monitor settings to non-volatile storage.`n`nError code: " Format("0x{:X}", A_LastError))
	}	
}

