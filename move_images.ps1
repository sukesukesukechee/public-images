# move_images.ps1

# このps1ファイルが置かれているフォルダを移動元にする
$sourceFolder = $PSScriptRoot

if ([string]::IsNullOrWhiteSpace($sourceFolder)) {
    $sourceFolder = (Get-Location).Path
}

function Select-FolderWithArrowKeys {
    param (
        [string]$BaseFolder
    )

    if (-not (Test-Path -Path $BaseFolder -PathType Container)) {
        Write-Host "基準フォルダが存在しません: $BaseFolder" -ForegroundColor Red
        exit 1
    }

    $folders = Get-ChildItem -Path $BaseFolder -Directory | Sort-Object Name

    if ($folders.Count -eq 0) {
        Write-Host "選択できるフォルダがありません: $BaseFolder" -ForegroundColor Yellow
        exit 0
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

# 移動先フォルダを矢印キーで選択
# 初期表示は、このps1が置かれているフォルダ直下のフォルダ一覧
$destinationFolder = Select-FolderWithArrowKeys -BaseFolder $sourceFolder

# 対象とする画像拡張子
$imageExtensions = @(
    ".jpg",
    ".jpeg",
    ".png",
    ".gif",
    ".bmp",
    ".webp",
    ".tif",
    ".tiff"
)

# ps1が置かれているフォルダ直下の画像ファイルのみ取得
$imageFiles = Get-ChildItem -Path $sourceFolder -File | Where-Object {
    $imageExtensions -contains $_.Extension.ToLower()
}

if ($imageFiles.Count -eq 0) {
    Write-Host "画像ファイルが見つかりませんでした。" -ForegroundColor Yellow
    Write-Host "対象フォルダ: $sourceFolder"
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