# vtscode.ps1 - Enhanced Windows PowerShell Version with Full Repo Context
param([string]$Question)

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
    function Get-DirectoryTree {
        param([string]$Path, [int]$Depth = 3, [int]$CurrentDepth = 0)
        
        if ($CurrentDepth -ge $Depth) { return }
        
        $items = Get-ChildItem -Path $Path -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notmatch '^(node_modules|\.git|dist|build|coverage)$' }
        
        foreach ($item in $items) {
            $indent = "  " * $CurrentDepth
            if ($item.PSIsContainer) {
                $context += "$indent$($item.Name)/`n"
                Get-DirectoryTree -Path $item.FullName -Depth $Depth -CurrentDepth ($CurrentDepth + 1)
            } else {
                $context += "$indent$($item.Name)`n"
            }
        }
    }
    
    Get-DirectoryTree -Path "." -Depth 3
    
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
        $tailwindConfig = Get-FileContent "tailwind.config.*" -MaxLines 30
        if ($tailwindConfig) {
            $context += "Tailwind config preview:`n$tailwindConfig`n"
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
    Write-Host "⚡ Vite + TypeScript React AI Assistant (Enhanced)" -ForegroundColor Cyan
    Write-Host "Performing deep analysis of your entire repository..." -ForegroundColor Yellow
    
    $context = Gather-ViteReactContext
    
    # Save context to temp file for large prompts
    $tempFile = [System.IO.Path]::GetTempFileName()
    Set-Content -Path $tempFile -Value $context
    
    $prompt = @"
You are a Vite + TypeScript + React expert. I've analyzed this entire repository:

$context

Based on this comprehensive analysis, suggest 5-7 specific, high-impact improvements:

1. Architecture improvements based on current structure
2. Performance optimizations specific to the codebase
3. TypeScript type safety enhancements
4. Component refactoring opportunities
5. State management improvements
6. Testing gaps that need attention
7. Build/deployment optimizations

Be specific to THIS codebase, reference actual files/components. Format as actionable tasks.
"@

    # Use file input for large context
    ollama run mixtral:8x7b $prompt
    
    Remove-Item $tempFile -ErrorAction SilentlyContinue
} else {
    Write-Host "Gathering full repository context..." -ForegroundColor Yellow
    $context = Gather-ViteReactContext
    
    # Save context to temp file
    $tempFile = [System.IO.Path]::GetTempFileName()
    Set-Content -Path $tempFile -Value $context
    
    $prompt = @"
You are a Vite + TypeScript + React expert with COMPLETE knowledge of this codebase.

FULL REPOSITORY CONTEXT:
$context

USER QUESTION: $Question

Provide a detailed, specific answer based on:
- The actual code and structure in THIS repository
- Reference specific files, components, and patterns you see
- Consider the dependencies and configurations present
- Suggest changes that fit the existing architecture
- Include code examples that match the project's style
- Consider the current state management approach
- Account for the routing structure
- Respect the existing TypeScript configurations

Your answer should be specifically tailored to THIS codebase, not generic advice.
"@

    # Use more powerful model for complex analysis
    ollama run mixtral:8x7b $prompt
    
    Remove-Item $tempFile -ErrorAction SilentlyContinue
}