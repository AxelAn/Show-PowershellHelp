###############################################################################################################################
# Name			: 	Show-PowershellHelp.ps1
# Description	: 	Powershell Help a little bit smarter!
# Author		: 	Axel Anderson 
# License		:	CC BY-SA 4.0
# Date			: 	27.06.2016 created (Source from GTFC.ps1 by Axel Anderson)
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Change:		27.06.2016	AAN		ReBuild from GTFC.ps1	
#									without remote exchange		
#
###############################################################################################################################
#
#Requires –Version 2
[CmdletBinding()]
Param   (
		)
Set-StrictMode -Version Latest	

#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#region Globals
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[System.Windows.Forms.Application]::EnableVisualStyles()
#endregion Globals

#region ScriptVariables

$script:ScriptName		= "Show-PowershellHelp"
$script:ScriptDesc		= "Powershell Help a little bit smarter!"
$script:ScriptDate		= "28. Juli 2016"
$script:ScriptAuthor	= "Axel Anderson"					
$script:ScriptVersion	= "2.0.5"

#Script Information
$script:WorkingFileName  = $MyInvocation.MyCommand.Definition
$script:WorkingDirectory = Split-Path $script:WorkingFileName -Parent
#
# THIS IS IMPORTTANT, if you use relative Path to WorkingDirectory
# 
Set-Location $script:WorkingDirectory
	
$script:PowershellCoreModules_23 = @(
										"Microsoft.Powershell.Core",
										"Microsoft.PowerShell.Diagnostic",
										"Microsoft.PowerShell.Host",
										"Microsoft.PowerShell.Management",
										"Microsoft.PowerShell.Security",
										"Microsoft.PowerShell.Utility",
										"Microsoft.WSMan.Management",
										"ISE",
										"PSScheduledJob",
										"PSWorkflow",
										"PSWorkflowUtility"
									)
$script:PowershellCoreModules_4 = @(
										"PSDesiredStateConfiguration"
									)
$script:PowershellCoreModules_5 = @(
										"Microsoft.PowerShell.Archive",
										"Microsoft.PowerShell.ODataUtils",
										"PackageManagement",
										"PowerShellget",
										"PSReadline",
										"PSScriptAnalyzer"
									)	

$script:PowershellCoreModules = $script:PowershellCoreModules_23
if ($PSVersionTable.PsVersion.Major -ge 4) { $script:PowershellCoreModules += $script:PowershellCoreModules_4}
if ($PSVersionTable.PsVersion.Major -ge 5) { $script:PowershellCoreModules += $script:PowershellCoreModules_5}

$script:Object_Standard = "Core-Modules"
$script:Object_Exchange = "Exchange"

$script:Sort_Name		= "Sort by Name"
$script:Sort_Verb		= "Sort by Verb"
$script:Sort_Noun		= "Sort by Noun"
$script:Sort_VerbNoun	= "Sort by Verb,Noun"
$script:Sort_NounVerb	= "Sort by Noun,Verb"

$script:SortValueNames = @($script:Sort_Name,$script:Sort_verb,$script:Sort_Noun,$script:Sort_VerbNoun,$script:Sort_NounVerb)
$script:SortValueHT  = @{
							$script:Sort_Name 		= @("Name");
							$script:Sort_verb 		= @("Verb");
							$script:Sort_Noun 		= @("Noun");
							$script:Sort_VerbNoun 	= @("Verb","Noun");
							$script:Sort_NounVerb 	= @("Noun","Verb");
						}
$script:CommandType_Cmdlet		= "Cmdlet"
$script:CommandType_Function	= "Function"
$script:CommandType_Alias		= "Alias"
$script:CommandType_About		= "About"
$script:CommandType_Provider	= "Provider"

#
# Note : provider info in PS 5 looks not like in versions before, so canceled at the moment
#
$script:CommandTypes = @(	
							$script:CommandType_Cmdlet,
							$script:CommandType_Function,
							$script:CommandType_Alias,
							$script:CommandType_About
							
						)
						
$script:InternalFunctionList = @("Show-PowershellHelpGUI","Fill-HelpBoxes","Reload-Data","New-ApplicationLauncherObject","Invoke-ApplicationLauncher","Select-FolderDialog","Show-InfoBox")
	
$script:TextStringWidth = 127
					 
#endregion ScriptVariables
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
function Show-InfoBox {
	$SB = new-Object text.stringbuilder
	$SB = $SB.AppendLine($script:ScriptName)
	$SB = $SB.AppendLine("`n")
	$SB = $SB.AppendLine($script:ScriptDesc+"`n")
	$SB = $SB.AppendLine("Last Changed:`t"+$script:ScriptDate)
	$SB = $SB.AppendLine("Author:`t`t"+$script:ScriptAuthor)
	$SB = $SB.AppendLine("Script-Version:`t"+$script:ScriptVersion)
	
	$d = [Windows.Forms.MessageBox]::Show($SB.toString(), "$script:ScriptName", 
	[Windows.Forms.MessageBoxButtons]::Ok, [Windows.Forms.MessageBoxIcon]::Information,
	[System.Windows.Forms.MessageBoxDefaultButton]::Button1)
}
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
Function Select-FolderDialog {
	[cmdletbinding()]
	Param	(
				[string]$Message="Select a folder",
				[string]$InitialDirectory=""
			)
	$FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog -Property @{
		Description = $message
		SelectedPath = $InitialDirectory
		ShowNewFolderButton = $false
	}
 
	if ($FolderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
		Write-output $FolderBrowser.SelectedPath
	} else {
		Write-output $Null
	}
} 
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
Function New-ApplicationLauncherObject {
	[cmdletbinding()]
	Param()
	#
	# Function taken from PSScriptLauncher.ps1 by AAN
	#
	$HData = @{
		Ident						= $(([string][guid]::NewGuid()).ToUpper())
		Name						= "unknown"
		Description					= "Description for unknown"
		# -------------------------------------------------------------------------------------------------------------------------
		Category1					= ""
		Category2					= ""
		Category3					= ""
		# -------------------------------------------------------------------------------------------------------------------------
		ExecutionType				= "psscript"		# psscript, programs
		# -------------------------------------------------------------------------------------------------------------------------
		PsProcessFilename			= 	""
		# -------------------------------------------------------------------------------------------------------------------------
		ArgumentList				=	""
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		UseElevated					= "0"
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		UseCredentials				= "0"
		CredentialUsername			= ""
		
		WorkingDirectory			=	""
		# -------------------------------------------------------------------------------------------------------------------------
		PSLaunchType				= 	"script"		# script, command, encodedcommand
		
		PSScriptFilename			=	""
		PSScriptArguments			=	""
		
		PSCommand					=	""
		PSEncodedCommand			=	""
		
	}
	
	$ApplicationLauncherObject = New-Object PSObject -Property $HData 

	Write-Output $ApplicationLauncherObject
}
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
Function Invoke-ApplicationLauncher {
	[cmdletbinding()]
	Param(
			[PSObject]$ExData
		 )

	#
	# Function taken from PSScriptLauncher.ps1 by AAN
	#
	
	$startArgs = @{
		ErrorAction = 'Stop';
	}		
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	$ArgumentList = ""
	# #####################################################################################
	if (($exData.ExecutionType -ieq "psscript") -or ($exData.ExecutionType -ieq "programs")){
		$startArgs.Add('FilePath',$exData.PsProcessFilename)
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		if ($exData.WorkingDirectory -ne "") {
			$startArgs.Add('WorkingDirectory',(''+$exData.WorkingDirectory+''))
		}
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		if ($exData.ArgumentList -ne "") {
			$ArgumentList = $exData.ArgumentList
		}
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		if ($exData.UseElevated -eq "1") {
			$startArgs.Add('Verb',"RunAs")
		}
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~		
		if 		 ($exData.PSLaunchType -ieq "script") {
			if (($ExData.PSScriptFilename -ne "") -and (Test-Path $ExData.PSScriptFilename)) {
				$argumentList = $ArgumentList + " -File " + ('"'+$ExData.PSScriptFilename+'"') +  $ExData.PSScriptArguments
			}
		} elseif ($exData.PSLaunchType -ieq "command") {
			if ($ExData.PSCommand -ne "") {
				$argumentList = $ArgumentList + ' -Command "& {' + $ExData.PSCommand + "}" + '"' 
			}
		} elseif ($exData.PSLaunchType -ieq "encodedcommand") {
			# ToDo
		}
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		if ($ArgumentList -ne "") {
			$startArgs.Add('ArgumentList',(''+$ArgumentList+''))
		}
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		
		try {
			if ($exData.UseCredentials  -eq "1") {
				$Cred = Get-Credential $exData.CredentialUsername
				Start-Job {Param($startArgs);Start-Process @startArgs} -ArgumentList $startArgs	-Credential $Cred	
			} else {
				Start-Process @startArgs
	
			}
		} catch {
			$_ | out-host
			$SB = new-Object text.stringbuilder
			$SB = $SB.AppendLine($script:ScriptName)
			$SB = $SB.AppendLine("`nCannot process this Item.`n")
			$SB = $SB.AppendLine("Please check the Parameter, validate path, arguments...")
			$SB = $SB.AppendLine("Check Powershell-Script and Command.")
			$SB = $SB.AppendLine("`n... and try again!`n")
			
			$d = [Windows.Forms.MessageBox]::Show($SB.toString(), "Invoke-ApplicationLauncher", 
			[Windows.Forms.MessageBoxButtons]::Ok, [Windows.Forms.MessageBoxIcon]::Information,
			[System.Windows.Forms.MessageBoxDefaultButton]::Button1)			
		}
	} 
}
#
# ---------------------------------------------------------------------------------------------------------------------------------
#
Function Show-PowershellHelpGUI {
[CmdletBinding()]
Param   (
		)
		
	# ---------------------------------------------------------------------------------------------------------------------	
	#region Local Helper Functions
	Function Fill-HelpBoxes {
		[CmdletBinding()]
		Param(
				[String]$Module,
				[string]$Object,
				[String]$Value
			 )

		Switch ($object) {
			($script:CommandType_Alias)	{
							$textboxCommand.Text = Get-Command $Value | format-list * | out-string -Width $script:TextStringWidth
							$textboxHelp.Text 	 = Get-help $Value -Full | out-string -Width $script:TextStringWidth
			
							break;
						}
			($script:CommandType_About)	{
							$textboxCommand.Text = ""
							$textboxHelp.Text 	 = Get-help $Value -Full | out-string -Width $script:TextStringWidth
							break;
						}
			($script:CommandType_Provider)	{
							$textboxCommand.Text = ""
							$textboxHelp.Text 	 = Get-help $Value -Full | out-string -Width $script:TextStringWidth
						}
			default		{
							switch ($Module) {
								$Script:Object_Standard	{
												$textboxCommand.Text = Get-Command $Value | format-list * | out-string -Width $script:TextStringWidth
												$textboxHelp.Text 	 = Get-help $Value -Full | out-string -Width $script:TextStringWidth
												break;
											}
								<#
								$Script:Object_Exchange	{
												break;
											}
								#>
								default		{
												$textboxCommand.Text = Get-Command $Value | format-list * | out-string -Width $script:TextStringWidth
												$textboxHelp.Text 	 = Get-help $Value -Full | out-string -Width $script:TextStringWidth
												break;
											}
							}
						}
		}
	}
	# ---------------------------------------------------------------------------------------------------------------------	
	Function Reload-Data {
		
		$Module 	= $comboBoxModule.text
		$Object 	= $comboBoxObject.text
		$SortValue 	= $comboBoxSort.text
		
		if (($Module -ne "") -and ($object -ne "")) {
			$StatusBarPanel1.Text = "Der Vorgang kann etwas dauern! Bitte ein wenig Geduld ...."
			
			if ($Module -ieq $script:Object_Standard) {		# CORE Modules
				$comboBoxSort.Enabled = $true
				
				$values = $null
				if ($Object -ieq $script:CommandType_About) {
				
					$values = get-help "about*" | % {$_.name}
					
				} elseif ($Object -ieq $script:CommandType_Alias) {
				
					$values = get-command -CommandType $Object |  % {$_.name}
					
				} elseif ($Object -ieq $script:CommandType_Provider) {
				
					$values = get-psprovider | % {$_.name}
				
				} elseif ($Object -ieq $script:CommandType_Function) {
					#
					# Note : Alle Functions ermitteln, auch die, die zu keinem Modul gehören 
					#		 Lokale Functions aber nicht !
					#		 28.6.2016 AAn Fehler behoben (Fehler übernommen aus GTFC)
					$tmpValues1 = get-command -CommandType $Object  | where-object {$_.ModuleName -eq ""} | where {-not($script:InternalFunctionList -icontains $_.Name)}
					$tmpValues2 = get-command -CommandType $Object -Module $PowershellCoreModules 
					
					$values = ($tmpValues1 + $tmpValues2)  | Sort-Object $script:SortValueHT[$SortValue] | % {$_.name}  
				} else {
					$values = get-command -CommandType $Object -Module $PowershellCoreModules |  Sort-Object $script:SortValueHT[$SortValue] | % {$_.name}  
				}
				
				if ($values) {
					$ListBox.Items.clear()
					foreach ($str in $Values) {
						$ListBox.Items.Add($str) | out-null
					}
					$listBox.SelectedIndex = 0
					$StatusBarPanel1.Text = "Ready"
				} else {
					
					$StatusBarPanel1.Text = "Keine Einträge gefunden ...."

					$listBox.Items.Clear()
					$textBoxTopHelp.Text = ""
					$textBoxBottomHelp.Text = ""
				}
			} elseif ($Module -ieq $script:Object_Exchange) {
				#
				# .... Later
				#
			} else {
				$comboBoxSort.Enabled = $true
				if (-not (Get-Module $Module)) { Import-Module $Module -Force }
				$values = get-command -CommandType $Object -Module $Module |  Sort-Object $script:SortValueHT[$SortValue] | % {$_.name}

				if ($values) {
					$ListBox.Items.clear()
					foreach ($str in $Values) {
						$ListBox.Items.Add($str) | out-null
					}
					$listBox.SelectedIndex = 0
					$StatusBarPanel1.Text = "Ready"
				} else {
					$listBox.Items.Clear()
					$textBoxCommand.Text = ""
					$textBoxHelp.Text = ""
					
					$StatusBarPanel1.Text = "Keine Einträge gefunden ...."
				}
			}
		}
	}
	#endregion Local Helper Functions
	# ---------------------------------------------------------------------------------------------------------------------	
	#region GUI BASE
	$padding	= 3
	
	$borderDist = 5
	$dist 		= 3
	
	$formWidth   = 900
	$formHeight  = 600	
	
	$comboBoxWidth = 200
	$LabelHeight = 22
	# ---------------------------------------------------------------------------------------------------------------------	
	$formMain							= New-Object System.Windows.Forms.Form	
		$PanelTop						= New-Object System.Windows.Forms.Panel	
			$ComboBoxObject				= New-Object System.Windows.Forms.ComboBox
			$ComboBoxModule				= New-Object System.Windows.Forms.ComboBox
			$ComboBoxSort				= New-Object System.Windows.Forms.ComboBox
			
		$PanelMain						= New-Object System.Windows.Forms.Panel
			$SplitContainerMain			= New-Object System.Windows.Forms.SplitContainer
				$ListBox				= New-Object System.Windows.Forms.ListBox
				$SplitContainerHelp		= New-Object System.Windows.Forms.SplitContainer
					$textboxCommand		= New-Object System.Windows.Forms.Textbox
					$textboxHelp		= New-Object System.Windows.Forms.Textbox
	
		$StatusBar					= New-Object System.Windows.Forms.StatusBar
		$StatusBarPanel1				= New-Object System.Windows.Forms.StatusBarPanel
		$StatusBarPanel2				= New-Object System.Windows.Forms.StatusBarPanel
		$StatusBarPanel3				= New-Object System.Windows.Forms.StatusBarPanel
		
		
	$consoleFont = New-Object System.Drawing.Font("Lucida Console", 8.25, [System.Drawing.FontStyle]::Regular)
	#endregion GUI BASE
	# ---------------------------------------------------------------------------------------------------------------------	
	#region CREATE MAINMENU
	
	$script:mainMenuStrip 							= New-Object System.Windows.Forms.MenuStrip
	$script:mainMenuItemMain						= New-Object System.Windows.Forms.ToolStripMenuItem
		$script:mainMenuItemExit					= New-Object System.Windows.Forms.ToolStripMenuItem
	$script:mainMenuItemAction						= New-Object System.Windows.Forms.ToolStripMenuItem
		$script:mainMenuItemImportModule			= New-Object System.Windows.Forms.ToolStripMenuItem
		$script:mainMenuItemUpdateHelp				= New-Object System.Windows.Forms.ToolStripMenuItem
		
		$script:mainMenuItemNotepadPlusPlus			= New-Object System.Windows.Forms.ToolStripMenuItem
		$script:mainMenuItemPSISE				= New-Object System.Windows.Forms.ToolStripMenuItem
		
		$script:mainMenuItemPSConsole				= New-Object System.Windows.Forms.ToolStripMenuItem
		$script:mainMenuItemPSConsoleElevated		= New-Object System.Windows.Forms.ToolStripMenuItem
		$script:mainMenuItemPSConsoleASUser			= New-Object System.Windows.Forms.ToolStripMenuItem
	$script:mainMenuItemQuestionmark				= New-Object System.Windows.Forms.ToolStripMenuItem
		$script:mainMenuItemInfo					= New-Object System.Windows.Forms.ToolStripMenuItem	
			
	$script:mainMenuItemExit | % {
		$_.Name = "mainMenuItemExit"
		$_.Size = New-Object System.Drawing.Size(155, 22)
		$_.Text = "Exit"
	}
	$script:mainMenuItemImportModule | % {
		$_.Name = "mainMenuItemImportModule"
		$_.Size = New-Object System.Drawing.Size(155, 22)
		$_.Text = "Import-Module"
	}
	$script:mainMenuItemUpdateHelp | % {
		$_.Name = "mainMenuItemUpdateHelp"
		$_.Size = New-Object System.Drawing.Size(155, 22)
		$_.Text = "Update-Help"
	}
	$script:mainMenuItemNotepadPlusPlus| % {
		$_.Name = "mainMenuItemNotepadPlusPlus"
		$_.Size = New-Object System.Drawing.Size(155, 22)
		$_.Text = "Notepad++"
	}
	$script:mainMenuItemPSISE| % {
		$_.Name = "mainMenuItemPSISE"
		$_.Size = New-Object System.Drawing.Size(155, 22)
		$_.Text = "Powershell ISE"
	}
	$script:mainMenuItemPSConsole | % {
		$_.Name = "mainMenuItemCredentials"
		$_.Size = New-Object System.Drawing.Size(155, 22)
		$_.Text = "PS Console"
	}
	$script:mainMenuItemPSConsoleElevated | % {
		$_.Name = "mainMenuItemCredentials"
		$_.Size = New-Object System.Drawing.Size(155, 22)
		$_.Text = "PS Console (elevated)"
	}
	$script:mainMenuItemPSConsoleASUser | % {
		$_.Name = "mainMenuItemCredentials"
		$_.Size = New-Object System.Drawing.Size(155, 22)
		$_.Text = "PS Console (as user, elevated)"
	}
	$script:mainMenuItemInfo | % {
		$_.Name = "mainMenuItemInfo"
		$_.Size = New-Object System.Drawing.Size(155, 22)
		$_.Text = "Info"
	}
	$script:mainMenuItemMain | % {
		$_.DropDownItems.AddRange([System.Windows.Forms.ToolStripItem[]](
			$script:mainMenuItemExit
		)) | Out-Null
		$_.Name = "mainMenuItemMain"
		$_.Size = New-Object System.Drawing.Size(37, 20)
		$_.Text = "Main"
		$_.DropDown.ShowImageMargin = $false
		$_.DropDown.ShowCheckMargin = $false
	}
	$script:mainMenuItemAction | % {
		$_.DropDownItems.AddRange([System.Windows.Forms.ToolStripItem[]](
			$script:mainMenuItemImportModule,
			(New-Object System.Windows.Forms.ToolStripSeparator),
			$script:mainMenuItemUpdateHelp,
			(New-Object System.Windows.Forms.ToolStripSeparator),
			$script:mainMenuItemNotepadPlusPlus,
			$script:mainMenuItemPSISE,
			(New-Object System.Windows.Forms.ToolStripSeparator),
			$script:mainMenuItemPSConsole,
			$script:mainMenuItemPSConsoleElevated,
			$script:mainMenuItemPSConsoleASUser
		))  | Out-Null
		$_.Name = "mainMenuItemAction"
		$_.Size = New-Object System.Drawing.Size(37, 20)
		$_.Text = "Action"
		$_.DropDown.ShowImageMargin = $false
		$_.DropDown.ShowCheckMargin = $false
	}	
	$script:mainMenuItemQuestionmark | % {
		$_.DropDownItems.AddRange([System.Windows.Forms.ToolStripItem[]](
			$script:mainMenuItemInfo
		)) | Out-Null

		$_.Name = "mainMenuItemQuestionmark"
		$_.Size = New-Object System.Drawing.Size(37, 20)
		$_.Text = "?"
		$_.DropDown.ShowImageMargin = $false
		$_.DropDown.ShowCheckMargin = $false
	}	
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	$script:mainMenuStrip | % {
		$_.BackColor = [System.Drawing.SystemColors]::Control
		$_.Items.Add($script:mainMenuItemMain) | Out-Null
		$_.Items.Add($script:mainMenuItemAction) | Out-Null
		$_.Items.Add($script:mainMenuItemQuestionmark) | Out-Null
		$_.Items[0].DropDown.ShowImageMargin = $false
		$_.Items[0].DropDown.ShowCheckMargin = $false	
		$_.Location = New-Object System.Drawing.Point(0, 0)
		$_.Name = "mainMenuStrip"
		$_.RenderMode = [System.Windows.Forms.ToolStripRenderMode]::System
		$_.Size = New-Object System.Drawing.Size(259, 22)
		$_.TabIndex = 1
		$_.Text = $Null
	}
	
	#endregion CREATE MAINMENU			
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#region MAINMENU ACTIONS
	$script:mainMenuItemExit.add_Click({ $formMain.Close() })
	$script:mainMenuItemImportModule.add_Click({
		#
		# Feel free to add additional Functions 
		# e.g. select psd1, psm1,ps1 and import and show the modules
		#
		$Path = Select-FolderDialog -Message "Bitte einen Modul-Pfad auswählen" -InitialDirectory $script:WorkingDirectory
		
		if ($Path) {
			$ValidProcessing = $True
			$RefMod = Get-Module
			try {
				Import-Module $Path -EA Stop
			} catch {
				
				Write-Error "Modul aus Pfad : $($Path) kann nicht geladen werden.`n$_"
				$ValidProcessing = $False
			}
			if ($ValidProcessing) {
				$DiffMod = Get-Module
		
				$NewMod = Compare-Object -ReferenceObject $RefMod -DifferenceObject $DiffMod -PassThru
				
				$NewMod | % {
					$comboBoxModule.Items.Add($_.Name) | out-host
				}
				$comboBoxModule.SelectedIndex = ($comboBoxModule.Items.Count-1)
			}
		}
	})		
	$script:mainMenuItemUpdateHelp.add_Click({
	
		$SB = new-Object text.stringbuilder
		$SB = $SB.AppendLine("UPDATE-HELP`n")
		$SB = $SB.AppendLine("Es wird das Cmdlet 'update-help -force -verbose' in einer neuen Console mit erweiterten Rechten (elevated) aufgerufen.")
		$SB = $SB.AppendLine("Dabei werden ALLE Powershell Core Module und ALLE Module im Powershell Modulpfad aktualisiert.`n`n")
		$SB = $SB.AppendLine("Stellen Sie sicher, das eine Internetverbindung besteht.`n")
		$SB = $SB.AppendLine("Stellen Sie sicher, das Sie mit einem administrativen Konto angemeldet sind.`n`n")
		$SB = $SB.AppendLine("Möchten Sie diesen Vorgang jetzt starten?`n")
		
		$d = [Windows.Forms.MessageBox]::Show($SB.toString(), "Update-Help", `
				[Windows.Forms.MessageBoxButtons]::YesNo, [Windows.Forms.MessageBoxIcon]::Information, `
				[System.Windows.Forms.MessageBoxDefaultButton]::Button2)	
		if ($d -eq "Yes") {
			$Executable = (Get-Command 'PowerShell.exe' | Select-Object -ExpandProperty Definition)
			$ALO = New-ApplicationLauncherObject
			$ALO.ExecutionType		= "psscript"
			$ALO.PsProcessFilename	= $Executable
			$ALo.WorkingDirectory	= $script:WorkingDirectory
			$ALO.ArgumentList		= ' -ExecutionPolicy UnRestricted'
			$ALO.PSLaunchType 		= "command"
			$ALO.PSCommand			= ("Set-Location "+$script:WorkingDirectory+";Update-Help -Force -Verbose;write-Host -n 'Press any key to continue .....';(Get-Host).UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')")
			$ALO.UseElevated		= "1"
			Invoke-ApplicationLauncher $ALO			
		}
	})
	$script:mainMenuItemNotepadPlusPlus.add_Click({
		$Executable = ( 'C:\Program Files (x86)\Notepad++\notepad++.exe' )
		$ALO = New-ApplicationLauncherObject
		$ALO.ExecutionType		= "programs"
		$ALO.PsProcessFilename	= $Executable
		$ALo.WorkingDirectory	= $script:WorkingDirectory
		
		Invoke-ApplicationLauncher $ALO
	})
	$script:mainMenuItemPSISE.add_Click({
		$Executable = (Get-Command 'PowerShell_ISE.exe' | Select-Object -ExpandProperty Definition)
		$ALO = New-ApplicationLauncherObject
		$ALO.ExecutionType		= "programs"
		$ALO.PsProcessFilename	= $Executable
		$ALo.WorkingDirectory	= $script:WorkingDirectory
		
		Invoke-ApplicationLauncher $ALO		
	})
	$script:mainMenuItemPSConsole.add_Click({
		$Executable = (Get-Command 'PowerShell.exe' | Select-Object -ExpandProperty Definition)
		$ALO = New-ApplicationLauncherObject
		$ALO.ExecutionType		= "programs"
		$ALO.PsProcessFilename	= $Executable
		$ALo.WorkingDirectory	= $script:WorkingDirectory
		$ALO.ArgumentList		= ' -NoExit -ExecutionPolicy UnRestricted'
		Invoke-ApplicationLauncher $ALO	
	
	})
	$script:mainMenuItemPSConsoleElevated.add_Click({
		$Executable = (Get-Command 'PowerShell.exe' | Select-Object -ExpandProperty Definition)
		$ALO = New-ApplicationLauncherObject
		$ALO.ExecutionType		= "programs"
		$ALO.PsProcessFilename	= $Executable
		$ALo.WorkingDirectory	= $script:WorkingDirectory
		$ALO.ArgumentList		= ' -NoExit -ExecutionPolicy UnRestricted'
		$ALO.PSLaunchType 		= "command"
		$ALO.PSCommand			= ('Set-Location '+$script:WorkingDirectory)
		$ALO.UseElevated		= "1"
		Invoke-ApplicationLauncher $ALO	
	})
	$script:mainMenuItemPSConsoleASUser.add_Click({
		$Executable = (Get-Command 'PowerShell.exe' | Select-Object -ExpandProperty Definition)
		$ALO = New-ApplicationLauncherObject
		$ALO.ExecutionType		= "psscript"
		$ALO.PsProcessFilename	= $Executable
		$ALo.WorkingDirectory	= $script:WorkingDirectory
		$ALO.ArgumentList		= ' -NoExit -ExecutionPolicy UnRestricted'
		$ALO.PSLaunchType 		= "command"
		$ALO.PSCommand			= ('Set-Location '+$script:WorkingDirectory)
		$ALO.UseCredentials		= "1"
		$ALO.UseElevated		= "1"
		Invoke-ApplicationLauncher $ALO	
	})
	$script:mainMenuItemInfo.add_Click({
	
		Show-InfoBox
	
	})	
#endregion MAINMENU ACTIONS	
	# ---------------------------------------------------------------------------------------------------------------------	
	#region GUI Controls		
	$textboxHelp | % {
		$_.Name 		= "textboxHelp"
		$_.Anchor		=([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right)
		$_.Location		= New-Object System.Drawing.Point(0,0)
		$_.Size			= New-Object System.Drawing.Size(0,0)
		$_.Dock			= [System.Windows.Forms.DockStyle]::Fill;
		$_.MultiLine 	= $true;
		$_.ReadOnly		= $true;
		$_.ScrollBars 	= "Both";
		$_.WordWrap   	= $false;
		$_.Font		  	= $consoleFont
		$_.TabStop 		= $false	
		$_.ReadOnly 	= $True
	}
	# ---------------------------------------------------------------------------------------------------------------------	
	$textboxCommand | % {
		$_.Name 		= "textboxCommand"
		$_.Anchor		=([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right)
		$_.Location		= New-Object System.Drawing.Point(0,0)
		$_.Size			= New-Object System.Drawing.Size(0,0)
		$_.Dock			= [System.Windows.Forms.DockStyle]::Fill;
		$_.MultiLine 	= $true;
		$_.ReadOnly		= $true;
		$_.ScrollBars 	= "Both";
		$_.WordWrap   	= $false;
		$_.Font		  	= $consoleFont
		$_.TabStop 		= $false	
		$_.ReadOnly 	= $True
	}
	# ---------------------------------------------------------------------------------------------------------------------	
	$SplitContainerHelp   | % {
		$_.Name 		= "SplitContainerHelp"
		$_.BackColor 	= [System.Drawing.Color]::Transparent
		$_.Dock 		= [System.Windows.Forms.DockStyle]::Fill
		$_.SplitterDistance = 30
		$_.SplitterWidth = 3
		$_.TabStop 		= $false
		
		# Horizontal, Vertical . Horizontal meint, Oben und unten, Vertical meint links und rechts
		$_.Orientation = [System.Windows.Forms.Orientation]::Horizontal
		
		$_.Panel1.Controls.Add($textboxCommand)
		$_.Panel2.Controls.Add($textboxHelp)		
	}
	# ---------------------------------------------------------------------------------------------------------------------		
	$ListBox | % {
		$_.Name 	= "listbox"
		$_.Location		= New-Object System.Drawing.Point(0,0)
		$_.Size			= New-Object System.Drawing.Size(0,0)
		$_.Dock			= [System.Windows.Forms.DockStyle]::Fill;	
		$_.Sorted 		= $false
		$_.IntegralHeight = $false		
		$_.TabStop 		= $false	
	}
	# ---------------------------------------------------------------------------------------------------------------------	
	$SplitContainerMain   | % {
		$_.Name 		= "SplitContainerMain"
		$_.BackColor 	= [System.Drawing.Color]::Transparent
		$_.Dock 		= [System.Windows.Forms.DockStyle]::Fill
		$_.SplitterDistance = 35
		$_.SplitterWidth = 3
		$_.TabStop 		= $false
		
		# Horizontal, Vertical . Horizontal meint, Oben und unten, Vertical meint links und rechts
		$_.Orientation = [System.Windows.Forms.Orientation]::Vertical
		
		$_.Panel1.Controls.Add($Listbox)
		$_.Panel2.Controls.Add($SplitContainerHelp)		
	}
	# ---------------------------------------------------------------------------------------------------------------------	
	$PanelMain  | % {
		$_.Autosize 	= $True
		$_.Anchor 		=([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right)
		$_.Dock 		= [System.Windows.Forms.DockStyle]::Fill
		$_.BackColor	= [System.Drawing.Color]::Transparent
		$_.Margin 		= New-Object System.Windows.Forms.Padding (0)
		$_.Padding 		= New-Object System.Windows.Forms.Padding (0,0,0,0)
		$_.Name 		= "PanelMain"
		$_.TabStop 		= $false
		$_.Controls.Add($SplitContainerMain)			
	}
	# ---------------------------------------------------------------------------------------------------------------------	
	$xPos = $borderDist
	$yPos = $borderDist
	
	$ComboBoxObject | % {
		$_.Location			= New-Object System.Drawing.Point($xPos,$yPos)
		$_.Name 			= "ComboBoxObject"
		$_.Size 			= New-Object System.Drawing.Size($comboBoxWidth, $labelHeight)
		$_.DropDownHeight 	= 400
		$_.DropDownStyle 	= [System.Windows.Forms.ComboBoxStyle]::DropDownList
		$_.FormattingEnabled = $True		
		$_.TabStop 			= $false		
	}
	# ---------------------------------------------------------------------------------------------------------------------	
	$xPos += $comboBoxWidth + $Dist
	
	$ComboBoxModule | % {
		$_.Location			= New-Object System.Drawing.Point($xPos,$yPos)
		$_.Name 			= "ComboBoxModule"
		$_.Size 			= New-Object System.Drawing.Size($comboBoxWidth, $labelHeight)
		$_.DropDownHeight 	= 400
		$_.DropDownStyle 	= [System.Windows.Forms.ComboBoxStyle]::DropDownList
		$_.FormattingEnabled = $True		
		$_.TabStop 			= $false		
	}	
	# ---------------------------------------------------------------------------------------------------------------------	
	$xPos += $comboBoxWidth + $Dist
	
	$ComboBoxSort | % {
		$_.Location			= New-Object System.Drawing.Point($xPos,$yPos)
		$_.Name 			= "ComboBoxSort"
		$_.Size 			= New-Object System.Drawing.Size($comboBoxWidth, $labelHeight)
		$_.DropDownHeight 	= 400
		$_.DropDownStyle 	= [System.Windows.Forms.ComboBoxStyle]::DropDownList
		$_.FormattingEnabled = $True		
		$_.TabStop 			= $false		
	}
	# ---------------------------------------------------------------------------------------------------------------------	
	$xPos += $comboBoxWidth + $Dist
	# ---------------------------------------------------------------------------------------------------------------------	
	$PanelTop | % {
		$_.Size 		= New-Object System.Drawing.Size(0,32)
		$_.Dock 		= [System.Windows.Forms.DockStyle]::Top
		$_.BackColor 	= [System.Drawing.Color]::Wheat
		$_.Margin 		= New-Object System.Windows.Forms.Padding (0)
		$_.Padding 		= New-Object System.Windows.Forms.Padding (0,0,0,0)
		$_.Name 		= "panelTop"
		$_.TabStop = $false
		$_.Controls.Add($ComboBoxObject)
		$_.Controls.Add($ComboBoxModule)
		$_.Controls.Add($ComboBoxSort)
	}	
	# ---------------------------------------------------------------------------------------------------------------------	
	$StatusBarPanel1 | % {
		$_.Name		= "statusBarPanel1"
		$_.Text 	= "Ready"
		$_.Width    = 300
		$_.MinWidth = 160
		$_.AutoSize = "Contents" # or None
	}
	$StatusBarPanel2 | % {
		$_.Name		= "statusBarPanel2"
		$_.Text 	= "WinVersion"
		$_.Width    = 100
		$_.MinWidth = 80
		$_.AutoSize = "Contents" # or None
	}
	$StatusBarPanel3 | % {
		$_.Name		= "statusBarPanel3"
		$_.Text 	= "PSVersion"
		$_.Width    = 100
		$_.MinWidth = 80
		$_.AutoSize = "Contents" # or None
	}
	$StatusBar | % {
		$_.ShowPanels = $True
		$_.Name = "statusBar"
		$_.TabStop = $false
		$_.Panels.Add($statusBarPanel1) | Out-Null
		$_.Panels.Add($statusBarPanel2) | Out-Null
		$_.Panels.Add($statusBarPanel3) | Out-Null
	}
	# ---------------------------------------------------------------------------------------------------------------------	
	$FormMain | % {
		$_.FormBorderStyle 	= [System.Windows.Forms.FormBorderStyle]::Sizable
		$_.BackColor 		= [System.Drawing.Color]::CornSilk
		$_.Name				= "formMain"
		$_.ControlBox 		= $True
		$_.ShowInTaskbar 	= $True
		$_.StartPosition 	= "CenterScreen"
		$_.ClientSize 		= New-Object System.Drawing.Size($formWidth, $formHeight)
		$_.Text 			= ($script:ScriptDesc)
		$_.Controls.Add($PanelMain)
		$_.Controls.Add($PanelTop)
		$_.Controls.Add($script:mainMenuStrip)	
		$_.Controls.Add($StatusBar)	
		$_.Font = New-Object System.Drawing.Font("Segoe UI",9, [System.Drawing.FontStyle]::Regular)
	}	
	#endregion GUI Controls
	# ---------------------------------------------------------------------------------------------------------------------	
	#region Fill Data Gui Controls
	$comboBoxObject.Items.Clear()
	$comboBoxObject.Items.AddRange($script:CommandTypes)
	$comboBoxObject.SelectedIndex = 0

	$Module = @($script:Object_Standard) + ($(Get-Module -ListAvailable | % {$_.name}) | select-object -unique | Sort-Object )
	$comboBoxModule.Items.Clear()
	$comboBoxModule.Items.AddRange($Module)
	$comboBoxModule.SelectedIndex = 0

	$comboBoxSort.Items.Clear()
	$comboBoxSort.Items.AddRange($script:SortValueNames)
	$comboBoxSort.SelectedIndex = 0
	
	#endregion Fill Data Gui Controls
	# ---------------------------------------------------------------------------------------------------------------------	
	#region Events GUI Controls
	$comboBoxObject.add_SelectedIndexChanged({
		Reload-Data
	})
	$comboBoxModule.add_SelectedIndexChanged({
		Reload-Data
	})
	$comboBoxSort.add_SelectedIndexChanged({
		Reload-Data
	})
	
	$ListBox.add_SelectedIndexChanged({
		$module = $comboBoxModule.text
		$object = $comboBoxObject.text
		Fill-HelpBoxes $module $object $this.Text	
	})
	
	$FormMain.add_Shown({$FormMain.Activate()})
	
	$StatusBarPanel3.Text = ("PSVersion {0}" -f $PSVersionTable.PSVersion.ToString())
	$OSInfo = Get-WmiObject Win32_OperatingSystem
	$StatusBarPanel2.Text = ("{0} - {1}" -f $OSInfo.Caption, $OSInfo.version)
	
	#endregion Events GUI Controls
	# ---------------------------------------------------------------------------------------------------------------------	
	
	#Fill first time DATA
	Reload-Data
	# ---------------------------------------------------------------------------------------------------------------------	
	$Result = $FormMain.ShowDialog()
	# ---------------------------------------------------------------------------------------------------------------------	
		
}
#
# ---------------------------------------------------------------------------------------------------------------------------------
#
###############################################################################################################################
# ##### MAIN
Show-PowershellHelpGUI
# ##### END MAIN
###############################################################################################################################
