#!/bin/bash
# AI Context Loader for Vaultwarden Infrastructure
# Loads appropriate AI context based on the development task

set -euo pipefail

# Colors for better output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly NC='\033[0m' # No Color

# Project root detection
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

show_help() {
    echo -e "${BLUE}🤖 AI Context Loader for Vaultwarden Infrastructure${NC}"
    echo ""
    echo -e "${GREEN}Usage:${NC}"
    echo "  $0 <context-type> [options]"
    echo ""
    echo -e "${GREEN}Context Types:${NC}"
    echo -e "  ${YELLOW}full${NC}          Complete project context (recommended for new tasks)"
    echo -e "  ${YELLOW}terraform${NC}     Infrastructure and Terraform/OpenTofu development"
    echo -e "  ${YELLOW}docker${NC}        Container and Docker Compose development"
    echo -e "  ${YELLOW}security${NC}      Security implementation and hardening"
    echo -e "  ${YELLOW}deployment${NC}    CI/CD and deployment automation"
    echo -e "  ${YELLOW}troubleshoot${NC}  Debugging and problem resolution"
    echo ""
    echo -e "${GREEN}Options:${NC}"
    echo -e "  ${YELLOW}-c, --copy${NC}       Copy context to clipboard (requires xclip/pbcopy)"
    echo -e "  ${YELLOW}-f, --file${NC}       Save context to file"
    echo -e "  ${YELLOW}-s, --stats${NC}      Show context statistics"
    echo -e "  ${YELLOW}-h, --help${NC}       Show this help message"
    echo ""
    echo -e "${GREEN}Examples:${NC}"
    echo "  $0 full                    # Show complete context"
    echo "  $0 terraform --copy        # Copy Terraform context to clipboard"
    echo "  $0 security --file         # Save security context to file"
    echo "  $0 docker --stats          # Show Docker context statistics"
    echo ""
    echo -e "${GREEN}Workflow Integration:${NC}"
    echo "  # Load context for your AI assistant before starting work"
    echo "  eval \"\$(./scripts/ai-context.sh terraform)\""
    echo "  # Then paste the context into your AI chat"
}

check_dependencies() {
    local missing_files=()
    
    # Check required context files
    local required_files=(
        ".ai/context-prompt.md"
        ".ai/terraform-context.md"
        ".ai/docker-context.md"
        ".ai/security-context.md"
        ".ai/deployment-context.md"
        ".ai/troubleshooting-context.md"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$PROJECT_ROOT/$file" ]]; then
            missing_files+=("$file")
        fi
    done
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        echo -e "${RED}❌ Missing required context files:${NC}" >&2
        printf '%s\n' "${missing_files[@]}" >&2
        echo -e "${YELLOW}💡 Please ensure all AI context files are present.${NC}" >&2
        return 1
    fi
}

get_context_stats() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local lines=$(wc -l < "$file")
        local words=$(wc -w < "$file")
        local chars=$(wc -c < "$file")
        echo "📊 Lines: $lines | Words: $words | Characters: $chars"
    else
        echo "❌ File not found"
    fi
}

load_context() {
    local context_type="$1"
    local output_file="${2:-}"
    
    echo -e "${BLUE}🤖 Loading AI context for: ${YELLOW}$context_type${NC}" >&2
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}" >&2
    echo "" >&2
    
    local context_content=""
    
    case "$context_type" in
        "full")
            echo -e "${GREEN}📋 Loading complete project context...${NC}" >&2
            context_content=$(cat "$PROJECT_ROOT/.ai/context-prompt.md")
            ;;
            
        "terraform"|"infra"|"infrastructure")
            echo -e "${GREEN}🏗️ Loading Terraform/Infrastructure context...${NC}" >&2
            context_content="$(cat "$PROJECT_ROOT/.ai/context-prompt.md")

---

# 🏗️ TERRAFORM/INFRASTRUCTURE FOCUSED CONTEXT

$(cat "$PROJECT_ROOT/.ai/terraform-context.md")"
            ;;
            
        "docker"|"container"|"containers")
            echo -e "${GREEN}🐳 Loading Docker/Container context...${NC}" >&2
            context_content="$(cat "$PROJECT_ROOT/.ai/context-prompt.md")

---

# 🐳 DOCKER/CONTAINER FOCUSED CONTEXT

$(cat "$PROJECT_ROOT/.ai/docker-context.md")"
            ;;
            
        "security"|"sec")
            echo -e "${GREEN}🔒 Loading Security context...${NC}" >&2
            context_content="$(cat "$PROJECT_ROOT/.ai/context-prompt.md")

---

# 🔒 SECURITY FOCUSED CONTEXT

$(cat "$PROJECT_ROOT/.ai/security-context.md")"
            ;;
            
        "deployment"|"deploy"|"cicd")
            echo -e "${GREEN}🚀 Loading Deployment context...${NC}" >&2
            context_content="$(cat "$PROJECT_ROOT/.ai/context-prompt.md")

---

# 🚀 DEPLOYMENT FOCUSED CONTEXT

$(cat "$PROJECT_ROOT/.ai/deployment-context.md")"
            ;;
            
        "troubleshoot"|"debug"|"fix")
            echo -e "${GREEN}🐛 Loading Troubleshooting context...${NC}" >&2
            context_content="$(cat "$PROJECT_ROOT/.ai/context-prompt.md")

---

# 🐛 TROUBLESHOOTING FOCUSED CONTEXT

$(cat "$PROJECT_ROOT/.ai/troubleshooting-context.md")"
            ;;
            
        *)
            echo -e "${RED}❌ Unknown context type: $context_type${NC}" >&2
            echo -e "${YELLOW}💡 Use --help to see available options${NC}" >&2
            return 1
            ;;
    esac
    
    # Output context
    if [[ -n "$output_file" ]]; then
        echo "$context_content" > "$output_file"
        echo -e "${GREEN}✅ Context saved to: $output_file${NC}" >&2
    else
        echo "$context_content"
    fi
    
    # Show usage tip
    echo "" >&2
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}" >&2
    echo -e "${YELLOW}💡 Copy the above context and paste it into your AI assistant${NC}" >&2
    echo -e "${YELLOW}   before asking development questions.${NC}" >&2
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}" >&2
}

copy_to_clipboard() {
    local content="$1"
    
    if command -v pbcopy >/dev/null 2>&1; then
        # macOS
        echo "$content" | pbcopy
        echo -e "${GREEN}✅ Context copied to clipboard (macOS)${NC}" >&2
    elif command -v xclip >/dev/null 2>&1; then
        # Linux with xclip
        echo "$content" | xclip -selection clipboard
        echo -e "${GREEN}✅ Context copied to clipboard (Linux/xclip)${NC}" >&2
    elif command -v wl-copy >/dev/null 2>&1; then
        # Linux with Wayland
        echo "$content" | wl-copy
        echo -e "${GREEN}✅ Context copied to clipboard (Linux/Wayland)${NC}" >&2
    else
        echo -e "${YELLOW}⚠️ Clipboard utility not found. Install xclip, wl-clipboard, or use --file option${NC}" >&2
        return 1
    fi
}

show_context_stats() {
    local context_type="$1"
    
    echo -e "${BLUE}📊 Context Statistics for: ${YELLOW}$context_type${NC}"
    echo ""
    
    case "$context_type" in
        "full")
            echo -e "${GREEN}Complete Project Context:${NC}"
            get_context_stats "$PROJECT_ROOT/.ai/context-prompt.md"
            ;;
        "terraform"|"infra"|"infrastructure")
            echo -e "${GREEN}Base Context:${NC}"
            get_context_stats "$PROJECT_ROOT/.ai/context-prompt.md"
            echo -e "${GREEN}Terraform Context:${NC}"
            get_context_stats "$PROJECT_ROOT/.ai/terraform-context.md"
            ;;
        "docker"|"container"|"containers")
            echo -e "${GREEN}Base Context:${NC}"  
            get_context_stats "$PROJECT_ROOT/.ai/context-prompt.md"
            echo -e "${GREEN}Docker Context:${NC}"
            get_context_stats "$PROJECT_ROOT/.ai/docker-context.md"
            ;;
        "security"|"sec")
            echo -e "${GREEN}Base Context:${NC}"
            get_context_stats "$PROJECT_ROOT/.ai/context-prompt.md"
            echo -e "${GREEN}Security Context:${NC}"
            get_context_stats "$PROJECT_ROOT/.ai/security-context.md"
            ;;
        "deployment"|"deploy"|"cicd")
            echo -e "${GREEN}Base Context:${NC}"
            get_context_stats "$PROJECT_ROOT/.ai/context-prompt.md"
            echo -e "${GREEN}Deployment Context:${NC}"
            get_context_stats "$PROJECT_ROOT/.ai/deployment-context.md"
            ;;
        "troubleshoot"|"debug"|"fix")
            echo -e "${GREEN}Base Context:${NC}"
            get_context_stats "$PROJECT_ROOT/.ai/context-prompt.md"
            echo -e "${GREEN}Troubleshooting Context:${NC}"
            get_context_stats "$PROJECT_ROOT/.ai/troubleshooting-context.md"
            ;;
        "all")
            echo -e "${GREEN}All Context Files:${NC}"
            for file in .ai/*.md; do
                echo -e "${YELLOW}$(basename "$file"):${NC}"
                get_context_stats "$PROJECT_ROOT/$file"
            done
            ;;
    esac
}

main() {
    cd "$PROJECT_ROOT"
    
    # Parse arguments
    local context_type=""
    local copy_mode=false
    local file_mode=false
    local file_name=""
    local stats_mode=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -c|--copy)
                copy_mode=true
                shift
                ;;
            -f|--file)
                file_mode=true
                if [[ -n "${2:-}" && ! "$2" =~ ^- ]]; then
                    file_name="$2"
                    shift 2
                else
                    file_name="ai-context-$(date +%Y%m%d-%H%M%S).md"
                    shift
                fi
                ;;
            -s|--stats)
                stats_mode=true
                shift
                ;;
            -*)
                echo -e "${RED}❌ Unknown option: $1${NC}" >&2
                show_help
                exit 1
                ;;
            *)
                if [[ -z "$context_type" ]]; then
                    context_type="$1"
                else
                    echo -e "${RED}❌ Multiple context types specified${NC}" >&2
                    show_help
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Default to full context if none specified
    if [[ -z "$context_type" ]]; then
        context_type="full"
    fi
    
    # Check dependencies
    check_dependencies
    
    # Handle stats mode
    if [[ "$stats_mode" == true ]]; then
        show_context_stats "$context_type"
        exit 0
    fi
    
    # Load and process context
    local context_content
    if [[ "$file_mode" == true ]]; then
        context_content=$(load_context "$context_type" "$file_name")
    else
        context_content=$(load_context "$context_type")
    fi
    
    # Copy to clipboard if requested
    if [[ "$copy_mode" == true ]]; then
        copy_to_clipboard "$context_content"
    fi
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
