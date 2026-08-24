# ============================================
# SIS v2.3 - Универсальный установщик софта
# ============================================

# Проверка прав администратора
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Запустите скрипт от имени администратора!" -ForegroundColor Red
    Start-Process PowerShell -Verb RunAs -ArgumentList "-File `"$PSCommandPath`""
    exit
}

# Определение архитектуры системы
$is64Bit = [Environment]::Is64BitOperatingSystem
$arch = if ($is64Bit) { "x64" } else { "x86" }

# ============================================
# ФУНКЦИЯ УСТАНОВКИ WINGET
# ============================================

function Install-WinGet {
    Write-Host "Winget не найден. Пытаюсь установить..." -ForegroundColor Yellow
    
    try {
        # Проверяем, установлен ли модуль Microsoft.WinGet.Client
        $module = Get-Module -ListAvailable -Name Microsoft.WinGet.Client
        if (-not $module) {
            Write-Host "Установка модуля Microsoft.WinGet.Client..." -ForegroundColor Yellow
            Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery -Scope CurrentUser -AllowClobber
        }
        
        # Импортируем модуль
        Import-Module Microsoft.WinGet.Client -Force
        
        # Запускаем Repair-WinGetPackageManager
        Write-Host "Запуск Repair-WinGetPackageManager..." -ForegroundColor Yellow
        Repair-WinGetPackageManager
        
        Write-Host "✓ Winget установлен!" -ForegroundColor Green
        
        # Проверяем, что Winget теперь доступен
        $null = Get-Command winget -ErrorAction Stop
        return $true
    }
    catch {
        Write-Host "✗ Не удалось установить Winget автоматически." -ForegroundColor Red
        Write-Host "Попробуйте установить вручную из Microsoft Store:" -ForegroundColor Yellow
        Write-Host "1. Откройте Microsoft Store" -ForegroundColor Gray
        Write-Host "2. Найдите 'App Installer'" -ForegroundColor Gray
        Write-Host "3. Нажмите 'Получить' или 'Обновить'" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Или скачайте: https://aka.ms/getwinget" -ForegroundColor Cyan
        return $false
    }
}

# Функция проверки Winget с автоматической установкой
function Check-Winget {
    try {
        $null = Get-Command winget -ErrorAction Stop
        return $true
    } catch {
        # Пытаемся установить Winget
        Write-Host "Winget не найден. Пытаюсь установить..." -ForegroundColor Yellow
        return Install-WinGet
    }
}

# Проверяем Winget, если не найден - устанавливаем
$useWinget = Check-Winget

# ============================================
# БАЗА ДАННЫХ ПРОГРАММ
# ============================================

$apps = @{
    # ----- БАЗОВЫЕ -----
    "7zip" = @{
        name = "7-Zip"
        url = if ($is64Bit) { "https://www.7-zip.org/a/7z2409-x64.exe" } else { "https://www.7-zip.org/a/7z2409.exe" }
        silent = "/S"
        winget = "7zip.7zip"
        category = "Базовые"
    }
    "vlc" = @{
        name = "VLC Media Player"
        url = "https://get.videolan.org/vlc/last/win64/vlc-3.0.21-win64.exe"
        silent = "/S"
        winget = "VideoLAN.VLC"
        category = "Базовые"
    }
    "notepadpp" = @{
        name = "Notepad++"
        url = "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.7.1/npp.8.7.1.Installer.x64.exe"
        silent = "/S"
        winget = "Notepad++.Notepad++"
        category = "Базовые"
    }
    "libreoffice" = @{
        name = "LibreOffice"
        url = if ($is64Bit) { "https://download.documentfoundation.org/libreoffice/stable/24.8.0/win/x86_64/LibreOffice_24.8.0_Win_x86-64.msi" } else { "https://download.documentfoundation.org/libreoffice/stable/24.8.0/win/x86/LibreOffice_24.8.0_Win_x86.msi" }
        silent = "/qn"
        winget = "TheDocumentFoundation.LibreOffice"
        category = "Базовые"
    }
    "gimp" = @{
        name = "GIMP"
        url = "https://download.gimp.org/mirror/pub/gimp/v2.10/gimp-2.10.38-setup-3.exe"
        silent = "/VERYSILENT"
        winget = "GIMP.GIMP"
        category = "Базовые"
    }
    "sumatra" = @{
        name = "SumatraPDF"
        url = "https://www.sumatrapdfreader.org/dl/rel/3.5.2/SumatraPDF-3.5.2-64-install.exe"
        silent = "-silent"
        winget = "SumatraPDF.SumatraPDF"
        category = "Базовые"
    }
    "killerpdf" = @{
        name = "KillerPDF"
        url = "https://github.com/SteveTheKiller/KillerPDF/releases/latest/download/KillerPDF.exe"
        silent = "/silent"
        winget = "SteveTheKiller.KillerPDF"  # исправлено
        category = "Базовые"
    }
    "adobereader" = @{
        name = "Adobe Acrobat Reader DC"
        url = if ($is64Bit) { 
            "https://ardownload2.adobe.com/pub/adobe/reader/win/AcrobatDC/2300820275/AcroRdrDCx642300820275_ru_RU.exe" 
        } else { 
            "https://ardownload2.adobe.com/pub/adobe/reader/win/AcrobatDC/2300820275/AcroRdrDC2300820275_ru_RU.exe" 
        }
        silent = "/sAll /rs /msi /qb-! /norestart"
        winget = "Adobe.Acrobat.Reader.64-bit"
        category = "Базовые"
    }
    "klite" = @{
        name = "K-Lite Codec Pack Full"
        url = "https://files3.codecguide.com/K-Lite_Codec_Pack_1905_Full.exe"
        silent = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART"
        winget = "CodecGuide.K-LiteCodecPack.Full"
        category = "Базовые"
    }
    
    # ----- СИСТЕМНЫЕ УТИЛИТЫ -----
    "wiztree" = @{
        name = "WizTree"
        url = "https://diskanalyzer.com/files/WizTree_4_32_setup.exe"
        silent = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART"
        winget = "AntibodySoftware.WizTree"  # исправленный ID
        category = "Системные утилиты"
    }
	"IObitUnlocker" = @{
        name = "IObitUnlocker"
        url = ""
        silent = "/quiet /norestart"
        winget = "IObit.IObitUnlocker"
        category = "Системные утилиты"
    }
    "java8" = @{
        name = "Java 8 Runtime (JRE)"
        url = "https://javadl.oracle.com/webapps/download/AutoDL?BundleId=248345_2a9c5b6b1a3a4a2a8b9c6a7b4c5d6e7f" # Пример ссылки, может меняться
        silent = "/s"
        winget = "Oracle.JavaRuntimeEnvironment"
        category = "Системные утилиты"
    }
	"dotnet8" = @{
        name = ".NET 8 Desktop Runtime"
        url = "https://dotnet.microsoft.com/en-us/download/dotnet/8.0" # Ссылка на страницу загрузки
        silent = "/quiet /norestart" # Ключи для тихой установки
        winget = "Microsoft.DotNet.DesktopRuntime.8"
        category = "Системные утилиты"
    }
    "everything" = @{
        name = "Everything"
        url = "https://www.voidtools.com/Everything-1.4.1.1026.x64-Setup.exe"
        silent = "/S"
        winget = "voidtools.Everything"
        category = "Системные утилиты"
	}
    "vscode" = @{
        name = "Visual Studio Code"
        url = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64"
        silent = "/verysilent /suppressmsgboxes /mergetasks=!runcode"
        winget = "Microsoft.VisualStudioCode"
        category = "Системные утилиты"
    }
	"qbittorrent" = @{
        name = "qBittorrent Enhanced Edition"
        url = "https://github.com/c0re100/qBittorrent-Enhanced-Edition/releases/latest/download/qbittorrent_enhanced_edition_x64_setup.exe"
        silent = "/S"
        winget = "c0re100.qBittorrent-Enhanced-Edition"
        category = "Системные утилиты"
	}
	"Rufus" = @{
        name = "Rufus #Rufus"
        url = ""
        silent = "/S"
        winget = "Rufus.Rufus"
        category = "Системные утилиты"
	    portable = $true
	}
	"sdi" = @{
        name = "SDI Origin(Lite) #sdio"
        url = "https://www.glenn.delahoy.com/snappy-driver-installer-origin/"
        silent = "/S"
        winget = "GlennDelahoy.SnappyDriverInstallerOrigin"
        category = "Системные утилиты"
        portable = $true
    }
	"HDD Low Level Format Tool" = @{
        name = "HDD Low Level Format Tool"
        url = "https://www.softportal.com/getsoft-4831-hdd-low-level-format-tool-2.html"
        silent = "/S"
        winget = "HDDGURU.HDDLLFTool"
        category = "Системные утилиты"
    }
	
# ----- БРАУЗЕРЫ -----
    "yandex" = @{
        name = "Яндекс Браузер"
        url = if ($is64Bit) { 
        "https://browser.yandex.ru/download/?bank=86&os=windows&lang=ru&bitness=64"
        } else { 
        "https://browser.yandex.ru/download/?bank=86&os=windows&lang=ru&bitness=32"
        }
        silent = "/S"
        winget = "Yandex.Browser"
        category = "Браузеры"
    }
    "chrome" = @{
        name = "Google Chrome"
        url = "https://dl.google.com/chrome/install/latest/chrome_installer.exe"
        silent = "/silent /install"
        winget = "Google.Chrome"
        category = "Браузеры"
    }
    "chromiumgost" = @{
        name = "Chromium-GOST"
        url = if ($is64Bit) { 
        "https://github.com/deemru/chromium-gost/releases/download/150.0.7871.224/chromium-gost-150.0.7871.224-windows-amd64-installer.exe"
        } else { 
        "https://github.com/deemru/chromium-gost/releases/download/150.0.7871.224/chromium-gost-150.0.7871.224-windows-386-installer.exe"
        }
        silent = "/S"
        # winget удалён (нет в репозитории)
        category = "Браузеры"
    }
    "supermium" = @{
        name = "Supermium Browser"
        url = if ($is64Bit) { 
        "https://github.com/win32ss/supermium/releases/download/144.0.7559.256-R5/supermium_144_64_setup_win10_11.exe"
        } else { 
        "https://github.com/win32ss/supermium/releases/download/144.0.7559.256-R5/supermium_144_32_setup.exe"
        }
        silent = "/S"
        winget = "win32ss.Supermium"
        category = "Браузеры"
    }
    "mozilla" = @{
        name = "Mozilla Firefox (рус.)"
        url = if ($is64Bit) { 
        "https://download.mozilla.org/?product=firefox-stub&os=win64&lang=ru"
        } else { 
        "https://download.mozilla.org/?product=firefox-stub&os=win32&lang=ru"
        }
        silent = "/S"
        winget = "Mozilla.Firefox"
        category = "Браузеры"
    }
    "firefox" = @{
        name = "Mozilla Firefox"
        url = "https://download.mozilla.org/?product=firefox-stub&os=win64&lang=ru"
        silent = "/S"
        winget = "Mozilla.Firefox"
        category = "Браузеры"
    }    
    # ----- ДИАГНОСТИКА -----
    "cpuz" = @{
        name = "CPU-Z"
        url = "https://www.cpuid.com/downloads/cpu-z/cpu-z_2.11-en.exe"
        silent = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART"
        winget = "CPUID.CPU-Z"
        category = "Диагностика"
    }
    "msiafterburner" = @{
        name = "MSI Afterburner"
        url = "https://download.msi.com/uti_exe/vga/MSIAfterburnerSetup.zip"
        silent = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART"
        winget = "Guru3D.Afterburner"
        category = "Диагностика"
    }
    "superposition" = @{
        name = "Superposition Benchmark"
        url = "https://benchmark.unigine.com/media/Unigine_Superposition-1.1.exe"
        silent = "/S"
        winget = "Unigine.SuperpositionBenchmark"
        category = "Диагностика"
    }
    "performancetest" = @{
        name = "PassMark PerformanceTest"
        url = "https://www.passmark.com/downloads/pt11.exe"
        silent = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART"
        winget = "PassMark.PerformanceTest"
        category = "Диагностика"
    }
    "bluescreenview" = @{
        name = "BlueScreenView"
        url = "https://www.nirsoft.net/utils/bluescreenview.zip"
        silent = "/S"
        winget = "NirSoft.BlueScreenView"
        category = "Диагностика"
    }
    "furmark" = @{
        name = "FurMark"
        url = "https://geeks3d.com/downloads/2025/FurMark_2.4.2.0_Setup.exe"
        silent = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART"
        winget = "Geeks3D.FurMark.2"
        category = "Диагностика"
    }
    "occt" = @{
        name = "OCCT"
        url = "https://www.ocbase.com/download/OCCT.exe"
        silent = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART"
        winget = "OCBase.OCCT.Personal"
        category = "Диагностика"
    }
	"CrystalDiskInfo " = @{
        name = "CrystalDiskInfo "
        url = ""
        silent = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART"
        winget = "CrystalDewWorld.CrystalDiskInfo"
        category = "Диагностика"
    }
	"Victoria" = @{
        name = "Victoria #Victoria"
        url = ""
        silent = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART"
        winget = "Victoria.Victoria"
        category = "Диагностика"
		portable = $true
    }
}

# ============================================
# ФУНКЦИЯ УСТАНОВКИ ПРОГРАММ
# ============================================

function Install-App {
    param($key)
    $app = $apps[$key]

    # Проверка, установлена ли уже программа
    $isInstalled = $false
    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    foreach ($path in $regPaths) {
        $installed = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*$($app.name)*" }
        if ($installed) {
            $isInstalled = $true
            break
        }
    }

    if ($isInstalled) {
        Write-Host "✓ $($app.name) уже установлен!" -ForegroundColor Green
        return
    }

    Write-Host "Скачивание $($app.name)..." -ForegroundColor Yellow

    $tempFile = "$env:TEMP\$key.exe"
    if ($app.url -match "\.msi$") {
        $tempFile = "$env:TEMP\$key.msi"
    } elseif ($app.url -match "\.zip$") {
        $tempFile = "$env:TEMP\$key.zip"
    }

    try {
        $webClient = New-Object System.Net.WebClient
        Register-ObjectEvent $webClient 'DownloadProgressChanged' -Action {
            $percent = $EventArgs.ProgressPercentage
            Write-Progress -Activity "Скачивание $($app.name)" -Status "$percent%" -PercentComplete $percent
        } | Out-Null
        $webClient.DownloadFile($app.url, $tempFile)

        Write-Host "Установка $($app.name)..." -ForegroundColor Yellow

        if ($tempFile -match "\.msi$") {
            $process = Start-Process -FilePath "msiexec" -ArgumentList "/i `"$tempFile`" $($app.silent) /norestart" -Wait -PassThru
        } elseif ($tempFile -match "\.zip$") {
            $extractPath = "$env:TEMP\$key"
            Expand-Archive -Path $tempFile -DestinationPath $extractPath -Force
            $exeFile = Get-ChildItem -Path $extractPath -Recurse -Filter "*.exe" | Select-Object -First 1
            if ($exeFile) {
                $process = Start-Process -FilePath $exeFile.FullName -ArgumentList $app.silent -Wait -PassThru
            } else {
                Write-Host "✗ Не найден установщик в архиве" -ForegroundColor Red
                return
            }
        } else {
            $process = Start-Process -FilePath $tempFile -ArgumentList $app.silent -Wait -PassThru
        }

        if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
            Write-Host "✓ $($app.name) установлен!" -ForegroundColor Green
            
            # ➕ ПОДСКАЗКА ДЛЯ ПОРТАТИВНЫХ ПРОГРАММ
            if ($app.portable -eq $true) {
                Write-Host ""
                Write-Host "📌 Это портативная версия." -ForegroundColor Yellow
                Write-Host "   Ярлык не создаётся. Чтобы запустить программу:" -ForegroundColor Yellow
                Write-Host "   ➤ Введите в PowerShell: $($app.name.ToLower())" -ForegroundColor Cyan
                Write-Host "   ➤ Или найдите файл в папке 'Загрузки'" -ForegroundColor Gray
                Write-Host ""
            }
        } else {
            Write-Host "✗ Ошибка при установке $($app.name) (код: $($process.ExitCode))" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "✗ Ошибка: $_" -ForegroundColor Red
    }
    finally {
        Remove-Item $tempFile -ErrorAction SilentlyContinue
        if ($tempFile -match "\.zip$") {
            Remove-Item "$env:TEMP\$key" -Recurse -ErrorAction SilentlyContinue
        }
        Get-EventSubscriber | Unregister-Event -ErrorAction SilentlyContinue
    }
}

# ============================================
# ФУНКЦИЯ ОТКРЫТИЯ СТРАНИЦЫ С СЕРТИФИКАТАМИ
# ============================================

function Download-Certificates {
    Clear-Host
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "    СЕРТИФИКАТЫ МИНЦИФРЫ" -ForegroundColor Yellow
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Открываю страницу с сертификатами на портале Госуслуг..." -ForegroundColor Yellow
    
    try {
        Start-Process "https://www.gosuslugi.ru/crt"
        Write-Host "✓ Страница открыта в браузере!" -ForegroundColor Green
        Write-Host ""
        Write-Host "📌 На странице нажмите кнопку 'Скачать сертификаты'." -ForegroundColor White
        Write-Host "После скачивания установите их согласно инструкции:" -ForegroundColor White
        Write-Host ""
        Write-Host "1. Дважды кликните на каждом .cer файле" -ForegroundColor Gray
        Write-Host "2. Нажмите 'Установить сертификат'" -ForegroundColor Gray
        Write-Host "3. Выберите 'Место хранения: Локальный компьютер'" -ForegroundColor Gray
        Write-Host "4. Выберите 'Поместить все сертификаты в следующее хранилище'" -ForegroundColor Gray
        Write-Host "5. Нажмите 'Обзор' и выберите 'Доверенные корневые центры сертификации'" -ForegroundColor Gray
        Write-Host "6. Нажмите 'Далее' и 'Готово'" -ForegroundColor Gray
        Write-Host ""
    }
    catch {
        Write-Host "✗ Не удалось открыть страницу: $_" -ForegroundColor Red
        Write-Host "Пожалуйста, откройте вручную: https://www.gosuslugi.ru/crt" -ForegroundColor Yellow
    }
    
    Read-Host "Нажмите Enter для продолжения"
}
# ============================================
# ФУНКЦИЯ УСТАНОВКИ OFFICE
# ============================================

function Install-Office {
    Clear-Host
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "    УСТАНОВКА MICROSOFT OFFICE" -ForegroundColor Yellow
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Выберите версию Office:" -ForegroundColor White
    Write-Host ""
    Write-Host "  [1] Office 2024" -ForegroundColor Green
    Write-Host "  [2] Office 2021" -ForegroundColor Green
    Write-Host "  [3] Microsoft 365" -ForegroundColor Green
    Write-Host "  [4] Office 2019" -ForegroundColor Green
    Write-Host "  [5] Office 2016" -ForegroundColor Green
    Write-Host "  [6] Office 2013" -ForegroundColor Green
    Write-Host ""
    Write-Host "  [0] Назад" -ForegroundColor Red
    Write-Host ""

    $choice = Read-Host "Ваш выбор"

    $officeUrls = @{
        "1" = "https://softnet.su/download/microsoft-office/office-2024/"
        "2" = "https://softnet.su/download/microsoft-office/office-2021/"
        "3" = "https://softnet.su/download/microsoft-office/office-365/"
        "4" = "https://softnet.su/download/microsoft-office/office-2019/"
        "5" = "https://softnet.su/download/microsoft-office/office-2016/"
        "6" = "https://softnet.su/download/microsoft-office/microsoft-office-2013/"
    }

    if ($choice -eq "0") { return }

    $url = $officeUrls[$choice]
    if (-not $url) {
        Write-Host "Неверный выбор!" -ForegroundColor Red
        Read-Host "Нажмите Enter"
        return
    }

    Write-Host "Открываем страницу с загрузкой Office..." -ForegroundColor Yellow
    Start-Process $url
    Write-Host ""
    Write-Host "На странице нажмите кнопку 'Скачать'." -ForegroundColor Cyan
    Write-Host "После скачивания ISO-образа:" -ForegroundColor White
    Write-Host "1. Откройте папку 'Загрузки'" -ForegroundColor Gray
    Write-Host "2. Запустите скачанный ISO-файл" -ForegroundColor Gray
    Write-Host "3. Следуйте инструкциям установщика" -ForegroundColor Gray
    Write-Host ""
    
    Read-Host "Нажмите Enter для продолжения"
}

# ============================================
# ФУНКЦИЯ УСТАНОВКИ VISUAL C++ (3 варианта)
# ============================================

function Install-VisualCpp {
    Clear-Host
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "    УСТАНОВКА VISUAL C++ REDISTRIBUTABLE" -ForegroundColor Yellow
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Выберите способ установки:" -ForegroundColor White
    Write-Host ""
    Write-Host "  [1] Через Winget (рекомендуется, если установлен)" -ForegroundColor Green
    Write-Host "  [2] Скачать EXE-файл (короткая ссылка)" -ForegroundColor Cyan
    Write-Host "  [3] Скачать ZIP-архив (парсинг сайта TechPowerUp)" -ForegroundColor Magenta
    Write-Host "  [4] Попробовать все варианты по очереди" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [0] Назад" -ForegroundColor Red
    Write-Host ""
    
    $choice = Read-Host "Ваш выбор"
    
    switch ($choice) {
        "0" { return }
        "1" { Install-VisualCpp-Winget }
        "2" { Install-VisualCpp-Exe }
        "3" { Install-VisualCpp-Zip }
        "4" { 
            Write-Host "Попытка установки через Winget..." -ForegroundColor Yellow
            Install-VisualCpp-Winget
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Winget не сработал, пробую EXE..." -ForegroundColor Yellow
                Install-VisualCpp-Exe
            }
            if ($LASTEXITCODE -ne 0) {
                Write-Host "EXE не сработал, пробую ZIP..." -ForegroundColor Yellow
                Install-VisualCpp-Zip
            }
        }
        default {
            Write-Host "Неверный выбор!" -ForegroundColor Red
        }
    }
    
    Read-Host "Нажмите Enter для продолжения"
}

# Вариант 1: Установка через Winget
function Install-VisualCpp-Winget {
    Write-Host "Установка Visual C++ Redistributable через Winget..." -ForegroundColor Yellow
    
    # Проверяем, установлен ли Winget
    try {
        $null = Get-Command winget -ErrorAction Stop
    } catch {
        Write-Host "✗ Winget не найден! Установите App Installer из Microsoft Store." -ForegroundColor Red
        $script:LASTEXITCODE = 1
        return
    }
    
    # Пытаемся установить
    winget install --id Microsoft.VCRedist.2015+.x64 --exact --silent --accept-package-agreements
    $exitCode = $LASTEXITCODE
    
    if ($exitCode -eq 0) {
        Write-Host "✓ Visual C++ установлен через Winget!" -ForegroundColor Green
    } elseif ($exitCode -eq -1978335189) {
        Write-Host "✓ Visual C++ уже установлен!" -ForegroundColor Green
    } else {
        Write-Host "✗ Ошибка при установке через Winget (код: $exitCode)" -ForegroundColor Red
        $script:LASTEXITCODE = $exitCode
    }
}

# Вариант 2: Скачивание EXE-файла по короткой ссылке
function Install-VisualCpp-Exe {
    Write-Host "Установка Visual C++ Redistributable через EXE-файл..." -ForegroundColor Yellow
    
    $vcUrl = "https://kutt.it/vcpp"
    $tempFile = "$env:TEMP\VC_Redist.exe"
    
    try {
        Write-Host "Скачивание EXE-файла..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri $vcUrl -OutFile $tempFile -UseBasicParsing
        
        Write-Host "Запуск установщика..." -ForegroundColor Yellow
        $process = Start-Process -FilePath $tempFile -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Host "✓ Visual C++ установлен через EXE!" -ForegroundColor Green
            $script:LASTEXITCODE = 0
        } else {
            Write-Host "✗ Ошибка при установке (код: $($process.ExitCode))" -ForegroundColor Red
            $script:LASTEXITCODE = $process.ExitCode
        }
    }
    catch {
        Write-Host "✗ Ошибка: $_" -ForegroundColor Red
        Write-Host "Попробуйте скачать вручную: https://kutt.it/vcpp" -ForegroundColor Yellow
        $script:LASTEXITCODE = 1
    }
    finally {
        Remove-Item $tempFile -ErrorAction SilentlyContinue
    }
}

# Вариант 3: Скачивание ZIP-архива через парсинг TechPowerUp
function Install-VisualCpp-Zip {
    Write-Host "Установка Visual C++ Redistributable через ZIP-архив..." -ForegroundColor Yellow
    
    $pageUrl = "https://www.techpowerup.com/download/visual-c-redistributable-runtime-package-all-in-one/"
    $tempZip = "$env:TEMP\VC_Redist.zip"
    $extractPath = "$env:TEMP\VC_Redist"
    
    try {
        Write-Host "Поиск ссылки на скачивание..." -ForegroundColor Yellow
        
        # Загружаем страницу и ищем ссылку на .zip файл
        $page = Invoke-WebRequest -Uri $pageUrl -UseBasicParsing
        $downloadLink = $page.Links | Where-Object { $_.href -match "\.zip$" } | Select-Object -First 1 -ExpandProperty href
        
        if (-not $downloadLink) {
            Write-Host "✗ Не найдена ссылка для скачивания" -ForegroundColor Red
            $script:LASTEXITCODE = 1
            return
        }
        
        # Убеждаемся, что ссылка абсолютная
        if ($downloadLink -notmatch "https?://") {
            $downloadLink = "https://www.techpowerup.com$downloadLink"
        }
        
        Write-Host "Скачивание: $downloadLink" -ForegroundColor Yellow
        Invoke-WebRequest -Uri $downloadLink -OutFile $tempZip -UseBasicParsing
        
        # Создаём папку для распаковки
        New-Item -ItemType Directory -Path $extractPath -Force | Out-Null
        
        # Распаковываем архив
        Write-Host "Распаковка архива..." -ForegroundColor Yellow
        Expand-Archive -Path $tempZip -DestinationPath $extractPath -Force
        
        # Запускаем установку
        $batFile = Get-ChildItem -Path $extractPath -Recurse -Filter "install_all.bat" | Select-Object -First 1
        if ($batFile) {
            Write-Host "Запуск install_all.bat..." -ForegroundColor Yellow
            $process = Start-Process -FilePath $batFile.FullName -Verb RunAs -Wait -PassThru
            
            if ($process.ExitCode -eq 0) {
                Write-Host "✓ Visual C++ установлен через ZIP!" -ForegroundColor Green
                $script:LASTEXITCODE = 0
            } else {
                Write-Host "✗ Ошибка при установке (код: $($process.ExitCode))" -ForegroundColor Red
                $script:LASTEXITCODE = $process.ExitCode
            }
        } else {
            Write-Host "✗ Не найден install_all.bat в архиве" -ForegroundColor Red
            $script:LASTEXITCODE = 1
        }
    }
    catch {
        Write-Host "✗ Ошибка: $_" -ForegroundColor Red
        Write-Host "Попробуйте скачать вручную: $pageUrl" -ForegroundColor Yellow
        $script:LASTEXITCODE = 1
    }
    finally {
        Remove-Item $tempZip -ErrorAction SilentlyContinue
        Remove-Item $extractPath -Recurse -ErrorAction SilentlyContinue
    }
}

# ============================================
# ФУНКЦИЯ ОТОБРАЖЕНИЯ ПОДМЕНЮ
# ============================================

function Show-SubMenu {
    param($category)
    
    Clear-Host
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "    $category" -ForegroundColor Yellow
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    
    $categoryApps = $apps.GetEnumerator() | Where-Object { $_.Value.category -eq $category } | Sort-Object Name
    
    $i = 1
    foreach ($app in $categoryApps) {
        Write-Host "  [$i] $($app.Value.name)" -ForegroundColor Green
        $i++
    }
    
    Write-Host ""
    Write-Host "  [A] Установить всё в этой категории" -ForegroundColor Yellow
    Write-Host "  [0] Назад" -ForegroundColor Red
    Write-Host ""
    
    $choice = Read-Host "Ваш выбор"
    
    if ($choice -eq "0") {
        return "back"
    }
    
    if ($choice -eq "A" -or $choice -eq "a") {
        Write-Host "Установка всех программ в категории '$category'..." -ForegroundColor Magenta
        foreach ($app in $categoryApps) {
            $key = $app.Key
            if ($useWinget -and $apps[$key].winget) {
                winget install --id $apps[$key].winget --exact --silent --accept-package-agreements
            } else {
                Install-App $key
            }
        }
        Write-Host "Все программы установлены!" -ForegroundColor Green
        Read-Host "Нажмите Enter для продолжения"
        return "back"
    }
    
    if ($choice -match "^\d+$") {
        $index = [int]$choice
        if ($index -ge 1 -and $index -le $categoryApps.Count) {
            $selectedApp = $categoryApps[$index - 1]
            $key = $selectedApp.Key
            if ($useWinget -and $apps[$key].winget) {
                winget install --id $apps[$key].winget --exact --silent --accept-package-agreements
            } else {
                Install-App $key
            }
            Read-Host "Нажмите Enter для продолжения"
            return "back"
        }
    }
    
    Write-Host "Неверный выбор!" -ForegroundColor Red
    Read-Host "Нажмите Enter для продолжения"
    return "back"
}

# ============================================
# ГЛАВНОЕ МЕНЮ
# ============================================

function Show-MainMenu {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "         SIS v2.3" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] Базовые программы (9)" -ForegroundColor Green
    Write-Host "  [2] Системные утилиты (10)" -ForegroundColor Cyan
    Write-Host "  [3] Браузеры (6)" -ForegroundColor Green
    Write-Host "  [4] Диагностика (9)" -ForegroundColor Magenta
    Write-Host ""
    #Write-Host "  [5] Установить всё сразу" -ForegroundColor Yellow
    Write-Host "  [6] Microsoft Office (выбор версии)" -ForegroundColor Yellow
    Write-Host "  [7] Visual C++ Redistributable AIO" -ForegroundColor Yellow
    Write-Host "  [8] Скачать сертификаты Минцифры" -ForegroundColor Yellow
    Write-Host "  [9] Установить/Обновить Winget" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [0] Выход" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Система: $($arch) | Winget: $(if ($useWinget) { 'Доступен' } else { 'Не найден' })" -ForegroundColor Magenta
    Write-Host ""
}

# ============================================
# ОСНОВНОЙ ЦИКЛ
# ============================================

$categories = @{
    "1" = "Базовые"
    "2" = "Системные утилиты"
    "3" = "Браузеры"
    "4" = "Диагностика"
}

do {
    Show-MainMenu
    $choice = Read-Host "Ваш выбор"
    
    switch ($choice) {
        "1" { Show-SubMenu "Базовые" }
        "2" { Show-SubMenu "Системные утилиты" }
        "3" { Show-SubMenu "Браузеры" }
        "4" { Show-SubMenu "Диагностика" }
        "5" {
            Write-Host "Установка ВСЕХ программ..." -ForegroundColor Magenta
            $allKeys = $apps.Keys
            foreach ($key in $allKeys) {
                if ($useWinget -and $apps[$key].winget) {
                    winget install --id $apps[$key].winget --exact --silent --accept-package-agreements
                } else {
                    Install-App $key
                }
            }
            Write-Host "Все программы установлены!" -ForegroundColor Green
            Read-Host "Нажмите Enter для продолжения"
        }
        "6" { Install-Office }
        "7" { Install-VisualCpp }
        "8" { Download-Certificates }
        "9" { 
            Write-Host "Установка/Обновление Winget..." -ForegroundColor Yellow
            $result = Install-WinGet
            if ($result) {
                $useWinget = $true
                Write-Host "✓ Winget успешно установлен!" -ForegroundColor Green
            } else {
                Write-Host "✗ Не удалось установить Winget" -ForegroundColor Red
            }
            Read-Host "Нажмите Enter для продолжения"
        }
        "0" {
            Write-Host "До свидания!" -ForegroundColor Yellow
            break
        }
        default {
            Write-Host "Неверный выбор" -ForegroundColor Red
            Read-Host "Нажмите Enter для продолжения"
        }
    }
} while ($choice -ne "0")
