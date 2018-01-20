#include <Timers.au3>
#include <Date.au3>
#include <Process.au3>
#Include <WinAPI.au3>
#include <GUIConstantsEx.au3>
#include <GuiListView.au3>
#include <Array.au3>

;;;;;;;;;;;;;;;;;;;;;
;; IdleMiner Config ;
;;;;;;;;;;;;;;;;;;;;;
$CONFIG_FILEPATH = @ScriptDir&"\idleminer_config.ini"
$IDLE_MINUTES = 3

;;;;;;;;;;;;;;;;;;;
; Claymore Config ;
;;;;;;;;;;;;;;;;;;;
$WORKER_NAME = Null
$ETH_WALLET_ADDR = Null
$SIA_WALLET_ADDR = Null

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Claymore Control Constants ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
$MINER_STARTED = False
$MINER_PID = Null

;;;;;;;;;;;;;;;;
; UI Constants ;
;;;;;;;;;;;;;;;;
$UI_CTRL_WORKER_NAME = Null
$UI_CTRL_IDLE_MINS = Null
$UI_CTRL_IDLE_PROGRESS = Null
$UI_CTRL_MANUAL_START = Null
$UI_CTRL_SAVE_SETTINGS = Null
$UI_CTRL_ETH_WAL = Null
$UI_CTRL_SIA_WAL = Null
$UI_CTRL_LOG = Null

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; IdleMiner Control Constants ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
$MANUAL_SKIP_COUNT = 0

;;;;;;;;;;;;;;;;;;;
; Begin Execution ;
;;;;;;;;;;;;;;;;;;;
ShowUI()
ReadSettings_File()
MainLoop()

;;;;;;;;;;;;;;;;;;;
;; Core Functions ;
;;;;;;;;;;;;;;;;;;;
Func MainLoop()
   UILog("Begin idle loop...")
   Local $uiMsg
   ; Loop until the user exits.
   While 1
	  Sleep(10)

	  ; Check for UI events
	  Switch GUIGetMsg()
	  Case $GUI_EVENT_CLOSE
			; User exited UI
			KillMiner()
			ExitLoop
		 Case $UI_CTRL_MANUAL_START
			; Start button
			StartMiner()
			$MANUAL_SKIP_COUNT = 300
			GUICtrlSetData($UI_CTRL_IDLE_PROGRESS, 100)
		 Case $UI_CTRL_SAVE_SETTINGS
			; Save settings
			ReadSettings_UI()
			WriteSettings_File()
	 EndSwitch

	  ; Main IdleMiner Loop
	  $idleTimer = _Timer_GetIdleTime()
	  If Not $MINER_STARTED and UserIsIdle($idleTimer) Then
		 StartMiner()
	  ElseIf $MINER_STARTED and UserNotIdle($idleTimer) Then
		 KillMiner()
	  EndIf
   WEnd
   UILog("Exiting IdleMiner...")
EndFunc

Func ShowUI()
   GUICreate("Claymore IdleMiner", 570, 500)

   GUICtrlCreateLabel("Worker Name:", 30, 14)
   $UI_CTRL_WORKER_NAME = GUICtrlCreateInput($WORKER_NAME, 160, 10, 240)

   GUICtrlCreateLabel("Idle Minutes:", 30, 39)
   $UI_CTRL_IDLE_MINS = GUICtrlCreateInput($IDLE_MINUTES, 160, 35, 60)

   $UI_CTRL_SAVE_SETTINGS = GUICtrlCreateButton("Save Settings", 230, 35)
   $UI_CTRL_MANUAL_START = GUICtrlCreateButton("Manual Start", 320, 35)

   GUICtrlCreateLabel("Eth Wallet Address:", 30, 94)
   $UI_CTRL_ETH_WAL = GUICtrlCreateInput($ETH_WALLET_ADDR, 160, 90, 300)

   GUICtrlCreateLabel("Sia Wallet Address:", 30, 124)
   $UI_CTRL_SIA_WAL = GUICtrlCreateInput($SIA_WALLET_ADDR, 160, 120, 300)

   GUICtrlCreateLabel("Time until miner starts:", 30, 180)
   $UI_CTRL_IDLE_PROGRESS = GUICtrlCreateProgress(30, 200, 500)

   GUICtrlCreateLabel("IdleMiner Log:", 30, 230)
   $UI_CTRL_LOG = GUICtrlCreateListView("Date|Message", 30, 250, 500, 150)
   _GUICtrlListView_SetColumnWidth($UI_CTRL_LOG, 0, 120)
   _GUICtrlListView_SetColumnWidth($UI_CTRL_LOG, 1, 370)

   GUISetState(@SW_SHOW)

   UILog("UI initialized.")
EndFunc

Func UILog($msg)
   GUICtrlCreateListViewItem(_Now()&"|"&$msg, $UI_CTRL_LOG)
EndFunc

Func ReadSettings_UI()
   $WORKER_NAME = GUICtrlRead($UI_CTRL_WORKER_NAME)
   $IDLE_MINUTES = GUICtrlRead($UI_CTRL_IDLE_MINS)
   $ETH_WALLET_ADDR = GUICtrlRead($UI_CTRL_ETH_WAL)
   $SIA_WALLET_ADDR = GUICtrlRead($UI_CTRL_SIA_WAL)
EndFunc

Func ReadSettings_File()
   $WORKER_NAME = IniRead($CONFIG_FILEPATH, "Claymore", "WorkerName", "windows_idleminer_default")
   $IDLE_MINUTES = int(IniRead($CONFIG_FILEPATH, "Idleminer", "IdleMinutes", "3"))
   $ETH_WALLET_ADDR = IniRead($CONFIG_FILEPATH, "Claymore", "EthWalletAddr", "0xd0a533941Cbe7785162Ca6E7CB7939b05763e85b")
   $SIA_WALLET_ADDR = IniRead($CONFIG_FILEPATH, "Claymore", "SiaWalletAddr", "ac6b0b90679fba581204ac5680275f7dd9e66001cd22f9fcd9b9c358e26a1334fe24b84e3b61")
   UpdateUI()
   UILog("Settings loaded from ini.")
EndFunc

Func WriteSettings_File()
   IniWrite($CONFIG_FILEPATH, "Claymore", "WorkerName", $WORKER_NAME)
   IniWrite($CONFIG_FILEPATH, "Idleminer", "IdleMinutes", $IDLE_MINUTES)
   IniWrite($CONFIG_FILEPATH, "Claymore", "EthWalletAddr", $ETH_WALLET_ADDR)
   IniWrite($CONFIG_FILEPATH, "Claymore", "SiaWalletAddr", $SIA_WALLET_ADDR)
   UILog("Settings saved.")
EndFunc

Func UpdateUI()
   GUICtrlSetData($UI_CTRL_WORKER_NAME, $WORKER_NAME)
   GUICtrlSetData($UI_CTRL_IDLE_MINS, $IDLE_MINUTES)
   GUICtrlSetData($UI_CTRL_ETH_WAL, $ETH_WALLET_ADDR)
   GUICtrlSetData($UI_CTRL_SIA_WAL, $SIA_WALLET_ADDR)
EndFunc

 Func UserIsIdle($idleTimer)
   Local $idleMax = ($IDLE_MINUTES * 60 * 1000)
   ;$idleMax = (3 * 1000)

   ; Update progress bar
   $progress = ($idleTimer / $idleMax) * 100
   GUICtrlSetData($UI_CTRL_IDLE_PROGRESS, $progress)

   Return $idleTimer > $idleMax
 EndFunc

 Func UserNotIdle($idleTimer)
	; Allow the user to be active for a few seconds
	; after clicking the manual start button.
	If $MANUAL_SKIP_COUNT > 0 Then
	   $MANUAL_SKIP_COUNT -= 1
	   Return False
	EndIf

	Return $idleTimer < 10
 EndFunc

 Func StartMiner()
	If Not $MINER_STARTED Then
	  ; Refresh settings from UI
	  ReadSettings_UI()
	  UILog("Starting Claymore Miner...")

	  Local $mArgs[8]
	  $mArgs[0] = "-epool eth-us-east1.nanopool.org:9999"
	  $mArgs[1] = "-ewal "&$ETH_WALLET_ADDR&"/"&$WORKER_NAME
	  $mArgs[2] = "-epsw x"
	  $mArgs[3] = "-ethi 9"
	  $mArgs[4] = "-dpool stratum+tcp://sia-us-east1.nanopool.org:7777"
	  $mArgs[5] = "-dwal "&$SIA_WALLET_ADDR&"/"&$WORKER_NAME
	  $mArgs[6] = "-dcoin sia"
	  $mArgs[7] = "-dcri 120"

	  Local $miner_args = _ArrayToString($mArgs, ' ')
	  ConsoleWrite("Miner Args: "&$miner_args)

	  $MINER_PID = ShellExecute(@ScriptDir & "\EthDcrMiner64.exe", $miner_args)
	  $MINER_STARTED = True
	EndIf
 EndFunc

 Func KillMiner()
	  If $MINER_STARTED Then
		 ProcessClose($MINER_PID)
		 UILog("Claymore Miner Killed.")
		 $MINER_STARTED = False
		 $MINER_PID = Null
	  EndIf
 EndFunc