# vtscode.ps1 - Enhanced with Auto-Apply Changes Feature
param(
    [string]$Question,
    [switch]$AutoApply,
    [switch]$Interactive
)

# ANSI color codes for better output
$script:Colors = @{
    Reset = "`e[0m"
    Red = "`e[31m"
    Green = "`e[32m"
    Yellow = "`e[33m"
    Blue = "`e[34m"
    Magenta = "`e[35m"
    Cyan = "`e[36m"
    Bold = "`e[1m"
}

function Write-ColorHost {
    param([string]$Message, [string]$Color = "Reset")
    Write-Host "$($script:Colors[$Color])$Message$($script:Colors.Reset)"
}

function Get-FileContent {
    param(
        [string]$Path,
        [int]$MaxLines = 100
    )
    try {
        $content = Get-Content $Path -TotalCount $MaxLines -ErrorAction SilentlyContinue
        return ($content -join "`n")
    } catch {
        return $null
    }
}

function Get-ImportantFiles {
    param([string]$Extension, [int]$MaxFiles = 10)
    
    $files = Get-ChildItem -Path . -Recurse -Include "*.$Extension" -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '(node_modules|\.git|dist|build|coverage)' } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First $MaxFiles
    
    return $files
}

function Parse-CodeBlocks {
    param([string]$Response)
    
    $codeBlocks = @()
    $pattern = '```(?<lang>\w+)?\s*\n(?<code>[\s\S]*?)```'
    $filePattern = '(?:(?://|#|--)\s*(?:File:|file:|FILE:)\s*(?<file>[^\n]+)|(?<file>[\w\./\-]+\.(?:tsx?|jsx?|css|scss|json|md|html|yml|yaml|env|config\.\w+)))'
    
    $matches = [regex]::Matches($Response, $pattern)
    
    foreach ($match in $matches) {
        $code = $match.Groups['code'].Value
        $lang = $match.Groups['lang'].Value
        
        # Try to extract filename from comment at the beginning of code block
        $firstLines = ($code -split "`n")[0..2] -join "`n"
        $fileMatch = [regex]::Match($firstLines, $filePattern)
        
        $fileName = $null
        if ($fileMatch.Success) {
            $fileName = $fileMatch.Groups['file'].Value.Trim()
            # Remove the filename comment from the code
            $code = $code -replace "^.*$([regex]::Escape($fileName)).*\n", ""
        }
        
        # If no filename in comment, check if the previous line mentions a file
        if (-not $fileName) {
            $startIndex = [Math]::Max(0, $match.Index - 200)
            $contextBefore = $Response.Substring($startIndex, $match.Index - $startIndex)
            $contextLines = ($contextBefore -split "`n")[-3..-1] -join "`n"
            
            if ($contextLines -match '(?:(?:create|update|modify|edit|change|Create|Update|Modify|Edit|Change)\s+)?(?:file\s+)?[`"]?([^\s`"]+\.(?:tsx?|jsx?|css|scss|json|md|html|yml|yaml|env|config\.\w+))[`"]?') {
                $fileName = $matches[1]
            }
        }
        
        if ($fileName -and $code.Trim()) {
            $codeBlocks += @{
                FileName = $fileName
                Language = $lang
                Code = $code.Trim()
                OriginalMatch = $match.Value
            }
        }
    }
    
    return $codeBlocks
}

function Parse-CommandInstructions {
    param([string]$Response)
    
    $commands = @()
    
    # Pattern for npm/yarn commands
    $cmdPattern = '(?:^|\n)\s*(?:npm|yarn|pnpm|npx)\s+[^\n]+'
    $cmdMatches = [regex]::Matches($Response, $cmdPattern)
    
    foreach ($match in $cmdMatches) {
        $cmd = $match.Value.Trim()
        if ($cmd -and $cmd -notmatch '```') {
            $commands += @{
                Type = "shell"
                Command = $cmd
            }
        }
    }
    
    # Pattern for file operations
    $fileOpPattern = '(?:^|\n)\s*(?:create|delete|rename|move|Create|Delete|Rename|Move)\s+(?:file|directory|folder)\s*:?\s*([^\n]+)'
    $fileOpMatches = [regex]::Matches($Response, $fileOpPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    
    foreach ($match in $fileOpMatches) {
        $operation = $match.Value.Trim()
        $commands += @{
            Type = "fileop"
            Command = $operation
        }
    }
    
    return $commands
}

function Show-ChangeSummary {
    param($CodeBlocks, $Commands)
    
    Write-ColorHost "`n📋 PROPOSED CHANGES SUMMARY" "Cyan"
    Write-ColorHost ("=" * 50) "Cyan"
    
    if ($CodeBlocks.Count -gt 0) {
        Write-ColorHost "`n📝 Files to modify:" "Yellow"
        foreach ($block in $CodeBlocks) {
            $exists = Test-Path $block.FileName
            $status = if ($exists) { "[UPDATE]" } else { "[CREATE]" }
            $statusColor = if ($exists) { "Yellow" } else { "Green" }
            Write-ColorHost "   $status $($block.FileName)" $statusColor
        }
    }
    
    if ($Commands.Count -gt 0) {
        Write-ColorHost "`n🔧 Commands to run:" "Yellow"
        foreach ($cmd in $Commands) {
            Write-ColorHost "   $($cmd.Command)" "Blue"
        }
    }
    
    Write-ColorHost "`n" "Reset"
}

function Backup-File {
    param([string]$FilePath)
    
    if (Test-Path $FilePath) {
        $backupDir = ".vtscode-backups"
        if (-not (Test-Path $backupDir)) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        }
        
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $fileName = Split-Path $FilePath -Leaf
        $backupPath = Join-Path $backupDir "$fileName.$timestamp.bak"
        
        Copy-Item -Path $FilePath -Destination $backupPath -Force
        return $backupPath
    }
    return $null
}

function Apply-CodeBlock {
    param($Block)
    
    $filePath = $Block.FileName
    $directory = Split-Path $filePath -Parent
    
    # Create directory if needed
    if ($directory -and -not (Test-Path $directory)) {
        Write-ColorHost "Creating directory: $directory" "Blue"
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    
    # Backup existing file
    $backupPath = Backup-File -FilePath $filePath
    if ($backupPath) {
        Write-ColorHost "Backed up: $filePath → $backupPath" "Magenta"
    }
    
    # Apply the change
    try {
        Set-Content -Path $filePath -Value $Block.Code -Encoding UTF8
        Write-ColorHost "✅ Applied changes to: $filePath" "Green"
        return $true
    } catch {
        Write-ColorHost "❌ Failed to apply changes to: $filePath - $_" "Red"
        if ($backupPath) {
            Copy-Item -Path $backupPath -Destination $filePath -Force
            Write-ColorHost "Restored from backup" "Yellow"
        }
        return $false
    }
}

function Execute-Command {
    param($Command)
    
    Write-ColorHost "Executing: $($Command.Command)" "Blue"
    
    try {
        if ($Command.Type -eq "shell") {
            $result = Invoke-Expression $Command.Command 2>&1
            Write-ColorHost "✅ Command executed successfully" "Green"
            if ($result) {
                Write-Host $result
            }
            return $true
        } elseif ($Command.Type -eq "fileop") {
            # Handle file operations
            if ($Command.Command -match '(?:create|Create)\s+(?:file|directory|folder)\s*:?\s*(.+)') {
                $path = $matches[1].Trim()
                if ($path -match '\.\w+$') {
                    # It's a file
                    New-Item -ItemType File -Path $path -Force | Out-Null
                } else {
                    # It's a directory
                    New-Item -ItemType Directory -Path $path -Force | Out-Null
                }
                Write-ColorHost "✅ Created: $path" "Green"
                return $true
            }
        }
    } catch {
        Write-ColorHost "❌ Command failed: $_" "Red"
        return $false
    }
}

function Apply-Changes {
    param(
        [string]$Response,
        [bool]$AutoApply,
        [bool]$Interactive
    )
    
    $codeBlocks = Parse-CodeBlocks -Response $Response
    $commands = Parse-CommandInstructions -Response $Response
    
    if ($codeBlocks.Count -eq 0 -and $commands.Count -eq 0) {
        Write-ColorHost "`nNo code changes or commands detected in the response." "Yellow"
        return
    }
    
    Show-ChangeSummary -CodeBlocks $codeBlocks -Commands $commands
    
    if (-not $AutoApply) {
        $apply = Read-Host "`nDo you want to apply these changes? (Y/N/I for interactive)"
        
        if ($apply -eq 'I') {
            $Interactive = $true
        } elseif ($apply -ne 'Y') {
            Write-ColorHost "Changes not applied." "Yellow"
            return
        }
    }
    
    # Apply code changes
    foreach ($block in $codeBlocks) {
        if ($Interactive) {
            Write-ColorHost "`n--- File: $($block.FileName) ---" "Cyan"
            Write-Host $block.Code
            Write-Host ""
            
            $action = Read-Host "Apply this change? (Y/N/S to skip all)"
            if ($action -eq 'S') {
                Write-ColorHost "Skipping remaining changes." "Yellow"
                break
            } elseif ($action -ne 'Y') {
                Write-ColorHost "Skipped: $($block.FileName)" "Yellow"
                continue
            }
        }
        
        Apply-CodeBlock -Block $block
    }
    
    # Execute commands
    foreach ($cmd in $commands) {
        if ($Interactive) {
            Write-ColorHost "`n--- Command ---" "Cyan"
            Write-Host $cmd.Command
            
            $action = Read-Host "`nExecute this command? (Y/N/S to skip all)"
            if ($action -eq 'S') {
                Write-ColorHost "Skipping remaining commands." "Yellow"
                break
            } elseif ($action -ne 'Y') {
                Write-ColorHost "Skipped command" "Yellow"
                continue
            }
        }
        
        Execute-Command -Command $cmd
    }
    
    Write-ColorHost "`n✨ All changes have been processed!" "Green"
    
    # Offer to run git diff
    if (Test-Path ".git") {
        $showDiff = Read-Host "`nShow git diff? (Y/N)"
        if ($showDiff -eq 'Y') {
            git diff
        }
    }
}

function Gather-ViteReactContext {
    Write-Host "Analyzing repository structure..." -ForegroundColor Yellow
    
    $context = @"
=== PROJECT OVERVIEW ===
Current directory: $(Get-Location)
Project type: Vite + TypeScript + React

"@
    
    # Git information
    if (Test-Path ".git") {
        try {
            $branch = git rev-parse --abbrev-ref HEAD 2>$null
            $lastCommit = git log -1 --pretty=format:"%h - %s" 2>$null
            $context += "Git branch: $branch`n"
            if ($lastCommit) { $context += "Last commit: $lastCommit`n" }
            
            $modifiedFiles = git diff --name-only 2>$null | Where-Object { $_ -match '\.(tsx?|jsx?|css|scss)$' }
            if ($modifiedFiles) {
                $context += "Modified files: $($modifiedFiles -join ', ')`n"
            }
        } catch {}
    }
    
    # Package.json analysis
    if (Test-Path "package.json") {
        $context += "`n=== PACKAGE CONFIGURATION ===`n"
        try {
            $packageContent = Get-Content "package.json" -Raw | ConvertFrom-Json
            $context += "Project name: $($packageContent.name)`n"
            $context += "Version: $($packageContent.version)`n"
            
            # Scripts
            if ($packageContent.scripts) {
                $scripts = $packageContent.scripts.PSObject.Properties.Name
                $context += "Available scripts: $($scripts -join ', ')`n"
            }
            
            # Dependencies
            $deps = @{}
            if ($packageContent.dependencies) {
                $packageContent.dependencies.PSObject.Properties | ForEach-Object {
                    $deps[$_.Name] = $_.Value
                }
            }
            if ($packageContent.devDependencies) {
                $packageContent.devDependencies.PSObject.Properties | ForEach-Object {
                    $deps[$_.Name] = $_.Value
                }
            }
            
            $context += "`nKey dependencies:`n"
            $keyPatterns = @('react', 'vite', 'typescript', 'router', 'redux', 'query', 'axios', 'tailwind', 'mui', 'antd')
            foreach ($pattern in $keyPatterns) {
                $matches = $deps.Keys | Where-Object { $_ -match $pattern }
                if ($matches) {
                    foreach ($dep in $matches) {
                        $context += "  - $dep@$($deps[$dep])`n"
                    }
                }
            }
        } catch {
            $context += "Error parsing package.json`n"
        }
    }
    
    # Vite configuration
    if (Test-Path "vite.config.ts") {
        $context += "`n=== VITE CONFIGURATION ===`n"
        $viteConfig = Get-FileContent "vite.config.ts" -MaxLines 50
        if ($viteConfig) {
            $context += "vite.config.ts preview:`n$viteConfig`n"
        }
    }
    
    # TypeScript configuration
    $context += "`n=== TYPESCRIPT CONFIGURATION ===`n"
    @("tsconfig.json", "tsconfig.app.json", "tsconfig.node.json") | ForEach-Object {
        if (Test-Path $_) {
            $tsConfig = Get-FileContent $_ -MaxLines 30
            if ($tsConfig) {
                $context += "$_ content:`n$tsConfig`n`n"
            }
        }
    }
    
    # Project structure
    $context += "`n=== PROJECT STRUCTURE ===`n"
    
    # Get directory tree (limited depth)
    $treeOutput = ""
    function Get-DirectoryTree {
        param([string]$Path, [int]$Depth = 3, [int]$CurrentDepth = 0, [string]$Indent = "")
        
        if ($CurrentDepth -ge $Depth) { return }
        
        $items = Get-ChildItem -Path $Path -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notmatch '^(node_modules|\.git|dist|build|coverage|\.vtscode-backups)$' }
        
        foreach ($item in $items) {
            $script:treeOutput += "$Indent$($item.Name)"
            if ($item.PSIsContainer) {
                $script:treeOutput += "/`n"
                Get-DirectoryTree -Path $item.FullName -Depth $Depth -CurrentDepth ($CurrentDepth + 1) -Indent "$Indent  "
            } else {
                $script:treeOutput += "`n"
            }
        }
    }
    
    Get-DirectoryTree -Path "." -Depth 3
    $context += $treeOutput
    
    # Source files analysis
    $context += "`n=== KEY SOURCE FILES ===`n"
    
    # Main entry files
    @("src/main.tsx", "src/App.tsx", "src/index.tsx") | ForEach-Object {
        if (Test-Path $_) {
            $content = Get-FileContent $_ -MaxLines 50
            if ($content) {
                $context += "`n--- $_ ---`n$content`n"
            }
        }
    }
    
    # Router configuration
    $routerFiles = Get-ChildItem -Path . -Recurse -Include "*router*", "*routes*" -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -match '\.(tsx?|jsx?)$' -and $_.FullName -notmatch 'node_modules' } |
        Select-Object -First 2
    
    foreach ($file in $routerFiles) {
        $content = Get-FileContent $file.FullName -MaxLines 50
        if ($content) {
            $context += "`n--- $($file.Name) ---`n$content`n"
        }
    }
    
    # Components
    if (Test-Path "src/components") {
        $context += "`n=== COMPONENTS ===`n"
        $components = Get-ChildItem -Path "src/components" -Recurse -Include "*.tsx", "*.jsx" -ErrorAction SilentlyContinue |
            Select-Object -First 5
        
        foreach ($comp in $components) {
            $content = Get-FileContent $comp.FullName -MaxLines 40
            if ($content) {
                $context += "`n--- Component: $($comp.Name) ---`n$content`n"
            }
        }
    }
    
    # Hooks
    if (Test-Path "src/hooks") {
        $context += "`n=== CUSTOM HOOKS ===`n"
        $hooks = Get-ChildItem -Path "src/hooks" -Recurse -Include "*.ts", "*.tsx" -ErrorAction SilentlyContinue |
            Select-Object -First 3
        
        foreach ($hook in $hooks) {
            $content = Get-FileContent $hook.FullName -MaxLines 40
            if ($content) {
                $context += "`n--- Hook: $($hook.Name) ---`n$content`n"
            }
        }
    }
    
    # State management
    $stateFiles = Get-ChildItem -Path . -Recurse -Include "*store*", "*redux*", "*context*" -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -match '\.(tsx?|jsx?)$' -and $_.FullName -notmatch 'node_modules' } |
        Select-Object -First 3
    
    if ($stateFiles) {
        $context += "`n=== STATE MANAGEMENT ===`n"
        foreach ($file in $stateFiles) {
            $content = Get-FileContent $file.FullName -MaxLines 40
            if ($content) {
                $context += "`n--- $($file.Name) ---`n$content`n"
            }
        }
    }
    
    # API/Services
    $apiFiles = Get-ChildItem -Path . -Recurse -Include "*api*", "*service*" -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -match '\.(tsx?|jsx?)$' -and $_.FullName -notmatch 'node_modules' } |
        Select-Object -First 3
    
    if ($apiFiles) {
        $context += "`n=== API/SERVICES ===`n"
        foreach ($file in $apiFiles) {
            $content = Get-FileContent $file.FullName -MaxLines 40
            if ($content) {
                $context += "`n--- $($file.Name) ---`n$content`n"
            }
        }
    }
    
    # Styles
    $context += "`n=== STYLING ===`n"
    
    # Check for CSS framework
    if (Test-Path "tailwind.config.js" -or Test-Path "tailwind.config.ts") {
        $context += "Styling: Tailwind CSS detected`n"
        $tailwindConfig = Get-ChildItem "tailwind.config.*" | Select-Object -First 1
        if ($tailwindConfig) {
            $content = Get-FileContent $tailwindConfig.FullName -MaxLines 30
            if ($content) {
                $context += "Tailwind config preview:`n$content`n"
            }
        }
    }
    
    # Global styles
    $styleFiles = Get-ChildItem -Path . -Recurse -Include "*.css", "*.scss", "*.module.css" -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch 'node_modules' } |
        Select-Object -First 3
    
    foreach ($style in $styleFiles) {
        $content = Get-FileContent $style.FullName -MaxLines 30
        if ($content) {
            $context += "`n--- Style: $($style.Name) ---`n$content`n"
        }
    }
    
    # Environment files
    $envFiles = Get-ChildItem -Path . -Include ".env*" -ErrorAction SilentlyContinue
    if ($envFiles) {
        $context += "`n=== ENVIRONMENT FILES ===`n"
        foreach ($env in $envFiles) {
            $context += "Found: $($env.Name)`n"
            # Read env file but hide values
            $envContent = Get-Content $env.FullName -ErrorAction SilentlyContinue
            foreach ($line in $envContent) {
                if ($line -match '^([^=]+)=') {
                    $context += "  Variable: $($matches[1])`n"
                }
            }
        }
    }
    
    # Testing setup
    $testFiles = Get-ChildItem -Path . -Recurse -Include "*.test.*", "*.spec.*", "jest.config.*", "vitest.config.*" -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch 'node_modules' } |
        Select-Object -First 3
    
    if ($testFiles) {
        $context += "`n=== TESTING SETUP ===`n"
        foreach ($test in $testFiles) {
            $context += "Test file: $($test.Name)`n"
        }
    }
    
    # ESLint/Prettier
    $context += "`n=== CODE QUALITY TOOLS ===`n"
    @("eslint.config.js", ".eslintrc.js", ".eslintrc.json", ".prettierrc", ".prettierrc.json") | ForEach-Object {
        if (Test-Path $_) {
            $context += "Found: $_`n"
            $content = Get-FileContent $_ -MaxLines 20
            if ($content) {
                $context += "Content preview:`n$content`n"
            }
        }
    }
    
    # Recent TypeScript/React files
    $context += "`n=== RECENTLY MODIFIED FILES ===`n"
    $recentFiles = Get-ImportantFiles -Extension "tsx" -MaxFiles 5
    foreach ($file in $recentFiles) {
        $relativePath = $file.FullName.Replace("$(Get-Location)\", "").Replace("\", "/")
        $context += "`n--- Recent: $relativePath ---`n"
        $content = Get-FileContent $file.FullName -MaxLines 50
        if ($content) {
            $context += "$content`n"
        }
    }
    
    return $context
}

# Main script logic
if (-not $Question) {
    Write-ColorHost "⚡ Vite + TypeScript React AI Assistant (with Auto-Apply)" "Cyan"
    Write-ColorHost "Performing deep analysis of your entire repository..." "Yellow"
    
    $context = Gather-ViteReactContext
    
    $prompt = @"
You are a Vite + TypeScript + React expert. I've analyzed this entire repository:

$context

Based on this comprehensive analysis, suggest 5-7 specific, high-impact improvements.

IMPORTANT: When suggesting code changes:
1. Always include the COMPLETE file content in code blocks
2. Add a comment with the filename at the top of each code block
3. Use proper markdown code blocks with language specification
4. For shell commands, write them clearly on separate lines

Example format:
\`\`\`typescript
// File: src/components/Button.tsx
import React from 'react';

export const Button = () => {
  return <button>Click me</button>;
};
\`\`\`

To install dependencies:
npm install package-name

Be specific to THIS codebase, reference actual files/components.
"@

    Write-ColorHost "`nGetting AI recommendations..." "Yellow"
    $tempFile = [System.IO.Path]::GetTempFileName()
    Set-Content -Path $tempFile -Value $prompt
    
    $response = & ollama run mixtral:8x7b "$(Get-Content $tempFile -Raw)"
    Write-Host $response
    
    Remove-Item $tempFile -ErrorAction SilentlyContinue
    
    # Offer to apply changes
    Apply-Changes -Response $response -AutoApply $AutoApply -Interactive $Interactive
    
} else {
    Write-ColorHost "Gathering full repository context..." "Yellow"
    $context = Gather-ViteReactContext
    
    $prompt = @"
You are a Vite + TypeScript + React expert with COMPLETE knowledge of this codebase.

FULL REPOSITORY CONTEXT:
$context

USER QUESTION: $Question

IMPORTANT INSTRUCTIONS:
1. Provide specific, actionable answers with COMPLETE code
2. When suggesting file changes, include the ENTIRE file content
3. Add filename comments at the top of code blocks
4. Use markdown code blocks with language specification
5. For commands, write them clearly (npm install, etc.)
6. Reference specific files from the codebase
7. Match the project's existing patterns and style

Format example:
\`\`\`typescript
// File: src/components/NewComponent.tsx
[COMPLETE file content here]
\`\`\`

Your answer should include ready-to-apply code changes.
"@

    Write-ColorHost "`nGetting AI response..." "Yellow"
    $tempFile = [System.IO.Path]::GetTempFileName()
    Set-Content -Path $tempFile -Value $prompt
    
    $response = & ollama run mixtral:8x7b "$(Get-Content $tempFile -Raw)"
    Write-Host $response
    
    Remove-Item $tempFile -ErrorAction SilentlyContinue
    
    # Apply changes if requested
    Apply-Changes -Response $response -AutoApply $AutoApply -Interactive $Interactive
}