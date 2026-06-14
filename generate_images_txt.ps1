# generate_images_txt.ps1

# このps1ファイルが置かれているフォルダを基準にする
$baseFolder = $PSScriptRoot

if ([string]::IsNullOrWhiteSpace($baseFolder)) {
    $baseFolder = (Get-Location).Path
}

# 出力する画像一覧ファイル名
$imageListFileName = "images.txt"
$imageListPath = Join-Path -Path $baseFolder -ChildPath $imageListFileName

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

function Convert-ToRelativePath {
    param (
        [string]$BasePath,
        [string]$TargetPath
    )

    $baseUri = New-Object System.Uri(($BasePath.TrimEnd('\') + '\'))
    $targetUri = New-Object System.Uri($TargetPath)

    $relativePath = $baseUri.MakeRelativeUri($targetUri).ToString()

    # GitHub Pages / HTML で扱いやすいように / 区切りへ統一
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
    Write-Host "基準フォルダ: $BaseFolder"
    Write-Host "一覧ファイル: $OutputPath"
    Write-Host "画像件数: $($relativePaths.Count)"
}

Update-ImageList -BaseFolder $baseFolder -OutputPath $imageListPath -Extensions $imageExtensions