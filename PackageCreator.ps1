#getting location of the package
while ($true) {
    $path = Read-Host -Prompt "Enter a path where you want to create package"
    if (Test-Path -Path $path) { break } #checking if path is valid

    Write-Host "Wrong path. Please try again" -ForegroundColor Red
}
Write-Host "Valid path: '$path'" -ForegroundColor Green

#getting the  name of package
while ($true){
	$name_of_package = read-host -Prompt "Enter the name of Package"
	if ($name_of_package){ #Checking if host entered something
		$package_path = -join ($path, $name_of_package)
		if (Test-Path -Path $package_path){ #Checking if folder already exists
			Write-Host "The folder '$package_path already exists'" -ForegroundColor Yellow
			while ($true) {
				$delete_check = read-host -Prompt "Do you want to delete everything inside that folder [y or n]"
				if ($delete_check -eq "y"){
					rm $package_path #deleting existing folder
					Write-Host "folder sucessfully deleted" -ForegroundColor Green
					break
				}
				elseif ($delete_check -ne "n"){
					Write-Host "Wrong answer, please write y or n" -ForegroundColor Red
				}
				break
			}
		if($delete_check -eq "y"){break}
			
		}
		else {break}
	}
	
	Write-Host "Wrong name. Please try again" -ForegroundColor Red
}

#creating a template of a package in said directory
cd $path
choco new "$name_of_package"


#moving installer to the package folder 
while ($true) {
    $path_to_installer = Read-Host -Prompt "Enter a path to installer"
    if (Test-Path -Path $path_to_installer) { #Checking if the path is valid
		$file=Get-Item "$path_to_installer"
		$fullfile = -join($file.Basename, $file.Extension)
		$extension = (Split-Path -Path $path_to_installer -Leaf).Split(".")[-1];
		if ($extension -eq "exe"){break}
		elseif ($extension -eq "msi"){break}
		elseif ($extension -eq "msu"){break}
		else{
			Write-Host "Wrong file extension. Please select a EXEMSI or MSU file" -ForegroundColor Red
		}
	}	

    Write-Host "Wrong path. Please try again" -ForegroundColor Red
}



Write-Host "Valid path: '$path_to_installer'" -ForegroundColor Green
copy $path_to_installer .\$name_of_package\tools
Write-Host "Installer is moved" -ForegroundColor Green

cd .\$name_of_package

#changing the version of package (nececary for it to work)
while ($true){
	[Version]$version = read-host -Prompt "Enter a version of a package"
	if ($version) {
		break
	}
	else{
		Write-Host "You entered wrong version, please only use numbers from 0 to 9 and dots" -ForegroundColor Red
	}
}
$author = read-host -Prompt "Enter the Author of software (press enter to skip)"
$description = read-host -Prompt "Enter the Description of sodtware (press enter to skip)"

$file = Get-ChildItem .\ *.nuspec
(Get-Content -Raw $file.PSPath).replace("<version>__REPLACE__</version>", "<version>$version</version>") | Set-Content $file.PSPath -NoNewLine
if ($author){
	(Get-Content -Raw $file.PSPath).replace("<authors>__REPLACE_AUTHORS_OF_SOFTWARE_COMMA_SEPARATED__</authors>", "<authors>$author</authors>") | Set-Content $file.PSPath -NoNewLine
	}
else{
	(Get-Content -Raw $file.PSPath).replace("<authors>__REPLACE_AUTHORS_OF_SOFTWARE_COMMA_SEPARATED__</authors>", "<authors>$packageName</authors>") | Set-Content $file.PSPath -NoNewLine
}
if($description){
	(Get-Content -Raw $file.PSPath).replace("<description>__REPLACE__MarkDown_Okay </description>", "<description>$description</description>") | Set-Content $file.PSPath -NoNewLine
}
else{
	(Get-Content -Raw $file.PSPath).replace("<description>__REPLACE__MarkDown_Okay </description>", "<description></description>") | Set-Content $file.PSPath -NoNewLine
}
Write-Host "version sucessfully changed" -ForegroundColor Green



cd .\tools

#configure chocolateyinstall
$chocoinstall= Get-ChildItem .\chocolateyinstall.ps1
(Get-Content -Raw $chocoinstall.PSPath).replace("NAME_OF_EMBEDDED_INSTALLER_FILE", "$fullfile") | Set-Content $chocoinstall.PSPath -NoNewLine
(Get-Content -Raw $chocoinstall.PSPath).replace('#$fileLocation = Join-Path', '$fileLocation = Join-Path') | Set-Content $chocoinstall.PSPath -NoNewLine #use '' if you want to treat $var as regular text
(Get-Content -Raw $chocoinstall.PSPath).replace("EXE_MSI_OR_MSU", "$extension") | Set-Content $chocoinstall.PSPath -NoNewLine
(Get-Content -Raw $chocoinstall.PSPath).replace("url           = $url", "#url           = $url") | Set-Content $chocoinstall.PSPath -NoNewLine
(Get-Content -Raw $chocoinstall.PSPath).replace("url64bit      = $url64", "#url64bit      = $url64") | Set-Content $chocoinstall.PSPath -NoNewLine
(Get-Content -Raw $chocoinstall.PSPath).replace("#file", "file") | Set-Content $chocoinstall.PSPath -NoNewLine
if ($extension -eq "exe"){
	$custom_args = read-host -Prompt "If you want to add custom arguments, enter them here. Press Etner to skip"
	if ($custom_args){
		(Get-Content -Raw $chocoinstall.PSPath).replace("#silentArgs   = '/S'", "silentArgs   = '$custom_args'") | Set-Content $chocoinstall.PSPath -NoNewLine
	}
	else {
		(Get-Content -Raw $chocoinstall.PSPath).replace("#silentArgs   = '/S'", "silentArgs   = '/S'") | Set-Content $chocoinstall.PSPath -NoNewLine
	}
	(Get-Content -Raw $chocoinstall.PSPath).replace('silentArgs    = "/qn', '#silentArgs    = "/qn') | Set-Content $chocoinstall.PSPath -NoNewLine
}
else{
	$custom_args = read-host -Prompt "If you want to add custom arguments, enter them here. Press Etner to skip"
	if ($custom_args){
		(Get-Content -Raw $chocoinstall.PSPath).replace('silentArgs    = "/qn /norestart /l*v `"$($env:TEMP)\$($packageName).$($env:chocolateyPackageVersion).MsiInstall.log`""', "silentArgs   = '$custom_args'") | Set-Content $chocoinstall.PSPath -NoNewLine
	}
}
Write-Host "Succesfully edited chocoinstall" -ForegroundColor Green

#deleting comments
Write-Host "Deleting comments..."
$f= "$chocoinstall"
gc $f | ? {$_ -notmatch "^\s*#"} | % {$_ -replace '(^.*?)\s*?[^``]#.*','$1'} | Out-File $f+".~" -en utf8; mv -fo $f+".~" $f
Write-Host "Comments sucessfully deleted" -ForegroundColor Green

#packing the package
cd ..
choco pack







Write-Host "###########################################################" -ForegroundColor Green
Write-Host "#                                                         #" -ForegroundColor Green
Write-Host "#                                                         #" -ForegroundColor Green
Write-Host "#               FINISHED SUCCESFULLY                      #" -ForegroundColor Green
Write-Host "#                                                         #" -ForegroundColor Green
Write-Host "#                                                         #" -ForegroundColor Green
Write-Host "###########################################################" -ForegroundColor Green
#Write-Host "finished" -ForegroundColor Green
cd ..
