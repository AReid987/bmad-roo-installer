#!/bin/bash
# Unified BMAD-METHOD + Roo Commander Installation & Integration
# Usage: curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/bmad-roo-installer/main/install-bmad-roo.sh | bash

set -e

echo "🚀 Installing BMAD-METHOD + Roo Commander Integration"
echo "=================================================="

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Not in a git repository. Please run from project root."
    exit 1
fi

# Check for pnpm
if ! command -v pnpm &> /dev/null; then
    echo "❌ pnpm is required but not installed. Please install pnpm first:"
    echo "   npm install -g pnpm"
    echo "   # or"
    echo "   curl -fsSL https://get.pnpm.io/install.sh | sh -"
    exit 1
fi

# Create necessary directories
echo "📁 Creating project structure..."
mkdir -p docs/{stories,prd,architecture}
mkdir -p project_journal/{tasks,decisions,formal_docs,visualizations,planning,technical_notes}
mkdir -p scripts

# Install BMAD-METHOD
echo ""
echo "📋 Installing BMAD-METHOD..."
if [ ! -d ".bmad-core" ]; then
    git clone https://github.com/bmadcode/BMAD-METHOD.git .bmad-temp
    mv .bmad-temp/.bmad-core .
    rm -rf .bmad-temp
    echo "✅ BMAD-METHOD installed"
else
    echo "⚠️  BMAD-METHOD already exists, updating..."
    cd .bmad-core && git pull origin main && cd ..
fi

# Install Roo Commander  
echo ""
echo "🎯 Installing Roo Commander..."
if [ ! -d ".roo" ]; then
    git clone https://github.com/jezweb/roo-commander.git .roo-temp
    mv .roo-temp/.roo .
    rm -rf .roo-temp
    echo "✅ Roo Commander installed"
else
    echo "⚠️  Roo Commander already exists, updating..."
    cd .roo && git pull origin main && cd ..
fi

# Create integration configuration
echo ""
echo "🔗 Setting up BMAD-Roo integration..."

# Create unified config
cat > .bmad-roo-config.yaml << 'EOFCONFIG'
# BMAD + Roo Commander Integration Configuration
integration:
  enabled: true
  handoff_trigger: "planning_complete"
  
bmad:
  docs_path: "docs/"
  stories_path: "docs/stories/"
  journal_path: "project_journal/"
  
roo:
  workspace_path: ".roo/"
  story_queue_path: ".roo/story-queue/"
  
handoff:
  auto_trigger: true
  validation_required: true
  artifacts_check:
    - "docs/project-brief.md"
    - "docs/prd.md" 
    - "docs/architecture.md"
    - "docs/stories/"
EOFCONFIG

# Create handoff automation script
cat > scripts/bmad-roo-handoff.js << 'EOFHANDOFF'
#!/usr/bin/env node
// BMAD to Roo Commander Handoff Automation

const fs = require('fs');
const path = require('path');

class BMadRooHandoff {
    constructor() {
        this.config = this.loadConfig();
    }

    loadConfig() {
        try {
            const yaml = require('js-yaml');
            return yaml.load(fs.readFileSync('.bmad-roo-config.yaml', 'utf8'));
        } catch (e) {
            console.error('❌ Config file not found or js-yaml not installed');
            console.error('Run: pnpm add js-yaml');
            process.exit(1);
        }
    }

    validateArtifacts() {
        const required = this.config.handoff.artifacts_check;
        const missing = [];
        const present = [];

        for (const artifact of required) {
            if (!fs.existsSync(artifact)) {
                missing.push(artifact);
            } else {
                present.push(artifact);
            }
        }

        return { missing, present };
    }

    executeHandoff() {
        console.log('🤝 Executing BMAD to Roo Commander handoff...');
        
        const { missing, present } = this.validateArtifacts();
        
        console.log('\n📋 Artifact Validation:');
        present.forEach(artifact => console.log(`  ✅ ${artifact}`));
        missing.forEach(artifact => console.log(`  ❌ ${artifact}`));
        
        if (missing.length > 0) {
            console.error('\n❌ Cannot proceed with handoff. Missing required artifacts.');
            console.error('💡 Use @bmad-orchestrator to create missing documentation.');
            return false;
        }

        // Create Roo story queue
        this.createStoryQueue();
        
        // Generate handoff summary
        this.generateHandoffSummary();
        
        console.log('\n✅ Handoff complete - Roo Commander ready for implementation');
        console.log('🚀 Use @roo-commander to begin development');
        return true;
    }

    createStoryQueue() {
        const storiesPath = this.config.bmad.stories_path;
        const queuePath = this.config.roo.story_queue_path;
        
        if (!fs.existsSync(queuePath)) {
            fs.mkdirSync(queuePath, { recursive: true });
        }

        // Copy stories to Roo queue
        if (fs.existsSync(storiesPath)) {
            const stories = fs.readdirSync(storiesPath).filter(file => file.endsWith('.md'));
            stories.forEach(story => {
                const src = path.join(storiesPath, story);
                const dest = path.join(queuePath, story);
                fs.copyFileSync(src, dest);
            });
            console.log(`📋 Queued ${stories.length} stories for implementation`);
        }
    }

    generateHandoffSummary() {
        const storiesCount = fs.existsSync(this.config.roo.story_queue_path) 
            ? fs.readdirSync(this.config.roo.story_queue_path).filter(f => f.endsWith('.md')).length 
            : 0;

        const summary = `# BMAD Planning Complete - Implementation Handoff

## 🎯 Planning Phase Summary
- ✅ Project documentation created
- ✅ Stories defined and prioritized  
- ✅ Architecture documented
- ✅ Ready for implementation

## 📋 Artifacts Created
- Project Brief: docs/project-brief.md
- PRD: docs/prd.md
- Architecture: docs/architecture.md
- Stories: docs/stories/ (${storiesCount} stories)

## 🚀 Next Steps for Roo Commander
1. Review story queue in .roo/story-queue/
2. Begin implementation following architecture guidelines
3. Update story status as work progresses

## 🔗 Integration Status
- Handoff Date: ${new Date().toISOString()}
- Stories Queued: ${storiesCount}
- Ready for Development: ✅

## 🎯 Development Commands
- \`@roo-commander\` - Start implementation
- \`pnpm roo:queue\` - Check story queue status
- \`pnpm roo:next\` - Get next story to implement

---
*Generated by BMAD-Roo Integration Bridge*
`;

        fs.writeFileSync('HANDOFF-SUMMARY.md', summary);
    }

    validateOnly() {
        console.log('🔍 Validating BMAD artifacts for handoff readiness...');
        
        const { missing, present } = this.validateArtifacts();
        
        console.log('\n📋 Artifact Status:');
        present.forEach(artifact => console.log(`  ✅ ${artifact}`));
        missing.forEach(artifact => console.log(`  ❌ ${artifact}`));
        
        if (missing.length === 0) {
            console.log('\n🎉 All artifacts present - Ready for handoff!');
            console.log('Run: pnpm bmad:handoff');
        } else {
            console.log('\n⚠️  Missing artifacts - Use @bmad-orchestrator to complete planning');
        }
        
        return missing.length === 0;
    }
}

// Handle command line arguments
const args = process.argv.slice(2);
const handoff = new BMadRooHandoff();

if (args.includes('--validate') || args.includes('-v')) {
    handoff.validateOnly();
} else {
    handoff.executeHandoff();
}

module.exports = BMadRooHandoff;
EOFHANDOFF

# Make handoff script executable
chmod +x scripts/bmad-roo-handoff.js

# Handle package.json - merge with existing or create new
if [ -f "package.json" ]; then
    echo "📦 Updating existing package.json..."
    # Create backup
    cp package.json package.json.backup
    
    # Use node to merge package.json
    node -e "
    const fs = require('fs');
    const existing = JSON.parse(fs.readFileSync('package.json', 'utf8'));
    
    // Ensure scripts object exists
    if (!existing.scripts) existing.scripts = {};
    
    // Add BMAD-Roo scripts
    existing.scripts['bmad:handoff'] = 'node scripts/bmad-roo-handoff.js';
    existing.scripts['bmad:validate'] = 'node scripts/bmad-roo-handoff.js --validate';
    existing.scripts['roo:start'] = 'echo \"🚀 Use @roo-commander to start implementation\"';
    existing.scripts['roo:queue'] = 'ls -la .roo/story-queue/ 2>/dev/null || echo \"📭 No stories queued yet\"';
    existing.scripts['roo:next'] = 'echo \"🎯 Use @roo-commander to get next story\"';
    
    // Ensure packageManager is set to pnpm
    existing.packageManager = existing.packageManager || 'pnpm@9.0.0';
    
    // Ensure dependencies object exists
    if (!existing.dependencies) existing.dependencies = {};
    if (!existing.devDependencies) existing.devDependencies = {};
    
    // Add required dependency
    existing.dependencies['js-yaml'] = '^4.1.0';
    
    fs.writeFileSync('package.json', JSON.stringify(existing, null, 2));
    console.log('✅ Updated package.json with BMAD-Roo scripts');
    "
else
    echo "📦 Creating package.json..."
    cat > package.json << 'EOFPACKAGE'
{
  "name": "bmad-roo-project",
  "version": "1.0.0",
  "description": "BMAD + Roo Commander integrated project",
  "packageManager": "pnpm@9.0.0",
  "scripts": {
    "bmad:handoff": "node scripts/bmad-roo-handoff.js",
    "bmad:validate": "node scripts/bmad-roo-handoff.js --validate",
    "roo:start": "echo '🚀 Use @roo-commander to start implementation'",
    "roo:queue": "ls -la .roo/story-queue/ 2>/dev/null || echo '📭 No stories queued yet'",
    "roo:next": "echo '🎯 Use @roo-commander to get next story'"
  },
  "dependencies": {
    "js-yaml": "^4.1.0"
  }
}
EOFPACKAGE
fi

# Install dependencies with pnpm
echo "📦 Installing dependencies with pnpm..."
pnpm install

# Update .gitignore
echo ""
echo "📝 Updating .gitignore..."
if [ -f ".gitignore" ]; then
    # Check if BMAD-Roo section already exists
    if ! grep -q "# BMAD-Roo Integration" .gitignore; then
        cat >> .gitignore << 'EOFGITIGNORE'

# BMAD-Roo Integration
HANDOFF-SUMMARY.md
.roo/story-queue/
package.json.backup
EOFGITIGNORE
    fi
else
    cat > .gitignore << 'EOFGITIGNORE'
# Dependencies
node_modules/

# BMAD-Roo Integration
HANDOFF-SUMMARY.md
.roo/story-queue/
package.json.backup
EOFGITIGNORE
fi

echo ""
echo "🎉 Installation Complete!"
echo "=================================================="
echo ""
echo "📋 BMAD-METHOD: Use @bmad-orchestrator to start planning"
echo "🎯 Roo Commander: Use @roo-commander for implementation"
echo ""
echo "🔧 Available Commands:"
echo "   pnpm bmad:handoff    - Execute handoff from planning to implementation"
echo "   pnpm bmad:validate   - Check if all artifacts are ready for handoff"
echo "   pnpm roo:queue       - Show current story queue status"
echo "   pnpm roo:start       - Reminder to use @roo-commander"
echo ""
echo "📁 Project structure created:"
echo "   docs/              - BMAD planning outputs"
echo "   project_journal/   - BMAD task logs"
echo "   .roo/             - Roo Commander workspace"
echo "   scripts/          - Integration scripts"
echo ""
echo "🚀 Next Steps:"
echo "1. Import your existing docs from Gemini web version to docs/ folder"
echo "2. Use @bmad-orchestrator to create/update planning documents"
echo "3. Run 'pnpm bmad:validate' to check readiness"
echo "4. Run 'pnpm bmad:handoff' when planning is complete"
echo "5. Use @roo-commander to begin implementation"
