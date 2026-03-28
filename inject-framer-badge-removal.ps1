<#
  Inserts the Framer badge-removal script before the first closing body tag in each .html file
  under the target folder. Skips files that already contain removeFramerBadge.

  Usage (from repo root):
    .\inject-framer-badge-removal.ps1
    .\inject-framer-badge-removal.ps1 -Root ".\katchkaro.framer.website"
#>
param(
	[string] $Root = (Split-Path -Parent $MyInvocation.MyCommand.Path)
)

$marker = 'removeFramerBadge'
$inject = @'
<script>
(function () {
	function removeFramerBadge() {
		document.querySelector('#__framer-badge-container')?.remove();
	}
	removeFramerBadge();
	new MutationObserver(removeFramerBadge).observe(document.documentElement, {
		childList: true,
		subtree: true,
	});
})();
</script>

'@

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$files = Get-ChildItem -LiteralPath $Root -Filter *.html -Recurse -File -ErrorAction SilentlyContinue
$updated = 0
$skipped = 0

foreach ($f in $files) {
	$text = [System.IO.File]::ReadAllText($f.FullName, $utf8NoBom)
	if ($text -notmatch [regex]::Escape($marker)) {
		$m = [regex]::Match($text, '(?i)</body>')
		if ($m.Success) {
			$new = $text.Substring(0, $m.Index) + $inject + $text.Substring($m.Index)
			[System.IO.File]::WriteAllText($f.FullName, $new, $utf8NoBom)
			$updated++
			Write-Host "Updated: $($f.FullName)"
		} else {
			Write-Warning "No closing body tag, skipped: $($f.FullName)"
		}
	} else {
		$skipped++
	}
}

Write-Host "Done. Updated: $updated  Already had script: $skipped  Total html: $($files.Count)"
