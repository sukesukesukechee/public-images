# move_images.ps1

# このps1ファイルが置かれているフォルダを移動元にする
$sourceFolder = $PSScriptRoot

if ([string]::IsNullOrWhiteSpace($sourceFolder)) {
    $sourceFolder = (Get-Location).Path
}

# 画像一覧ファイル名
$imageListFileName = "images.txt"
$imageListPath = Join-Path -Path $sourceFolder -ChildPath $imageListFileName

# 対象とする画像拡張子
$imageExtensions = @(
    ".jpg",
    ".jpeg",
    ".png",
    ".gif",
    ".bmp",
    ".webp",
    ".tif",
    ".tiff",
    ".svg"
)

function Select-FolderWithArrowKeys {
    param (
        [string]$BaseFolder
    )

    if (-not (Test-Path -Path $BaseFolder -PathType Container)) {
        Write-Host "基準フォルダが存在しません: $BaseFolder" -ForegroundColor Red
        exit 1
    }

    $folders = @(Get-ChildItem -Path $BaseFolder -Directory | Sort-Object Name)

    if ($folders.Count -eq 0) {
        Write-Host "選択できるフォルダがありません: $BaseFolder" -ForegroundColor Yellow
        exit 0
    }

    # フォルダが1つだけなら選択不要
    if ($folders.Count -eq 1) {
        Write-Host "移動先フォルダが1つだけのため、自動選択します。" -ForegroundColor Cyan
        Write-Host "移動先フォルダ: $($folders[0].FullName)"
        return $folders[0].FullName
    }

    $selectedIndex = 0

    while ($true) {
        Clear-Host

        Write-Host "画像の移動先フォルダを選択してください"
        Write-Host "基準フォルダ: $BaseFolder"
        Write-Host ""
        Write-Host "↑ / ↓ : 選択"
        Write-Host "Enter : 決定"
        Write-Host "Esc   : 中止"
        Write-Host ""

        for ($i = 0; $i -lt $folders.Count; $i++) {
            if ($i -eq $selectedIndex) {
                Write-Host ("> " + $folders[$i].Name) -ForegroundColor Cyan
            }
            else {
                Write-Host ("  " + $folders[$i].Name)
            }
        }

        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

        switch ($key.VirtualKeyCode) {
            38 {
                # Up
                if ($selectedIndex -gt 0) {
                    $selectedIndex--
                }
            }
            40 {
                # Down
                if ($selectedIndex -lt ($folders.Count - 1)) {
                    $selectedIndex++
                }
            }
            13 {
                # Enter
                return $folders[$selectedIndex].FullName
            }
            27 {
                # Esc
                Write-Host "処理を中止しました。" -ForegroundColor Yellow
                exit 0
            }
        }
    }
}

function Convert-ToRelativePath {
    param (
        [string]$BasePath,
        [string]$TargetPath
    )

    $baseUri = New-Object System.Uri(($BasePath.TrimEnd('\') + '\'))
    $targetUri = New-Object System.Uri($TargetPath)

    $relativePath = $baseUri.MakeRelativeUri($targetUri).ToString()

    # URL形式の / に統一
    return [System.Uri]::UnescapeDataString($relativePath).Replace('\', '/')
}

function Update-ImageList {
    param (
        [string]$BaseFolder,
        [string]$OutputPath,
        [string[]]$Extensions
    )

    $imageFiles = Get-ChildItem -Path $BaseFolder -Recurse -File | Where-Object {
        $Extensions -contains $_.Extension.ToLower()
    } | Sort-Object FullName

    $relativePaths = @()

    foreach ($file in $imageFiles) {
        $relativePaths += Convert-ToRelativePath -BasePath $BaseFolder -TargetPath $file.FullName
    }

    $relativePaths | Set-Content -Path $OutputPath -Encoding UTF8

    Write-Host ""
    Write-Host "画像一覧ファイルを生成しました。" -ForegroundColor Green
    Write-Host "一覧ファイル: $OutputPath"
}

# 移動先フォルダを選択
# フォルダが1つだけなら自動選択
$destinationFolder = Select-FolderWithArrowKeys -BaseFolder $sourceFolder

# ps1が置かれているフォルダ直下の画像ファイルのみ取得
$imageFiles = @(Get-ChildItem -Path $sourceFolder -File | Where-Object {
    $imageExtensions -contains $_.Extension.ToLower()
})

if ($imageFiles.Count -eq 0) {
    Write-Host "画像ファイルが見つかりませんでした。" -ForegroundColor Yellow
    Write-Host "対象フォルダ: $sourceFolder"

    # 画像がなくても、現在存在する画像一覧は毎回生成する
    Update-ImageList -BaseFolder $sourceFolder -OutputPath $imageListPath -Extensions $imageExtensions

    exit 0
}

foreach ($file in $imageFiles) {
    $extension = $file.Extension.ToLower()

    # ユニークなファイル名を作成
    $uniqueName = "{0}_{1}{2}" -f `
        (Get-Date -Format "yyyyMMdd_HHmmssfff"), `
        ([guid]::NewGuid().ToString("N")), `
        $extension

    $destinationPath = Join-Path -Path $destinationFolder -ChildPath $uniqueName

    Move-Item -Path $file.FullName -Destination $destinationPath

    Write-Host "移動完了: $($file.Name) -> $uniqueName"
}

Write-Host ""
Write-Host "すべての画像ファイルの移動が完了しました。" -ForegroundColor Green
Write-Host "移動元フォルダ: $sourceFolder"
Write-Host "移動先フォルダ: $destinationFolder"

# 実行完了時に、実行階層フォルダへ画像一覧を相対パスで生成
Update-ImageList -BaseFolder $sourceFolder -OutputPath $imageListPath -Extensions $imageExtensions