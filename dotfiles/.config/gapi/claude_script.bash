#!/bin/bash

# Google API AI Automation Script
# Requires: jq, curl, gcloud CLI (optional)

set -euo pipefail

# Configuration
CONFIG_FILE="${HOME}/.google-api-ai/config.json"
CACHE_DIR="${HOME}/.google-api-ai/cache"
LOG_FILE="${HOME}/.google-api-ai/automation.log"

# API Configuration (set these as environment variables or in config)
GOOGLE_API_KEY="${GOOGLE_API_KEY:-}"
CLAUDE_API_KEY="${CLAUDE_API_KEY:-}"
GOOGLE_OAUTH_TOKEN="${GOOGLE_OAUTH_TOKEN:-}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Initialize directories
init_dirs() {
    mkdir -p "$(dirname "$CONFIG_FILE")"
    mkdir -p "$CACHE_DIR"
    touch "$LOG_FILE"
}

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Error handling
error() {
    echo -e "${RED}ERROR: $*${NC}" >&2
    log "ERROR: $*"
    exit 1
}

success() {
    echo -e "${GREEN}✓ $*${NC}"
    log "SUCCESS: $*"
}

warning() {
    echo -e "${YELLOW}⚠ $*${NC}"
    log "WARNING: $*"
}

# Check dependencies
check_deps() {
    local deps=("jq" "curl")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            error "$dep is required but not installed"
        fi
    done
}

# Call Claude AI for intelligent assistance
call_claude() {
    local prompt="$1"
    local context="${2:-}"
    
    if [[ -z "$CLAUDE_API_KEY" ]]; then
        warning "CLAUDE_API_KEY not set, skipping AI assistance"
        return 1
    fi
    
    local full_prompt="$prompt"
    if [[ -n "$context" ]]; then
        full_prompt="Context: $context\n\nTask: $prompt"
    fi
    
    local response=$(curl -s https://api.anthropic.com/v1/messages \
        -H "Content-Type: application/json" \
        -H "x-api-key: $CLAUDE_API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -d "{
            \"model\": \"claude-sonnet-4-20250514\",
            \"max_tokens\": 4096,
            \"messages\": [{
                \"role\": \"user\",
                \"content\": $(echo "$full_prompt" | jq -Rs .)
            }]
        }")
    
    echo "$response" | jq -r '.content[0].text'
}

# Google API call wrapper
google_api_call() {
    local endpoint="$1"
    local method="${2:-GET}"
    local data="${3:-}"
    local use_oauth="${4:-false}"
    
    local auth_header=""
    if [[ "$use_oauth" == "true" ]]; then
        [[ -z "$GOOGLE_OAUTH_TOKEN" ]] && error "GOOGLE_OAUTH_TOKEN not set"
        auth_header="Authorization: Bearer $GOOGLE_OAUTH_TOKEN"
    else
        [[ -z "$GOOGLE_API_KEY" ]] && error "GOOGLE_API_KEY not set"
        endpoint="${endpoint}?key=${GOOGLE_API_KEY}"
    fi
    
    local curl_args=(-s -X "$method")
    [[ -n "$auth_header" ]] && curl_args+=(-H "$auth_header")
    [[ -n "$data" ]] && curl_args+=(-H "Content-Type: application/json" -d "$data")
    
    local response=$(curl "${curl_args[@]}" "$endpoint")
    echo "$response"
}

# Gmail: Send email
gmail_send() {
    local to="$1"
    local subject="$2"
    local body="$3"
    
    log "Sending email to: $to"
    
    local email_raw=$(cat <<EOF | base64 -w 0
To: $to
Subject: $subject
Content-Type: text/html; charset=utf-8

$body
EOF
)
    
    local data=$(jq -n --arg raw "$email_raw" '{raw: $raw}')
    
    local response=$(google_api_call \
        "https://gmail.googleapis.com/gmail/v1/users/me/messages/send" \
        "POST" \
        "$data" \
        "true")
    
    if echo "$response" | jq -e '.id' > /dev/null; then
        success "Email sent successfully"
        echo "$response" | jq -r '.id'
    else
        error "Failed to send email: $(echo "$response" | jq -r '.error.message // "Unknown error"')"
    fi
}

# Gmail: List emails with AI filtering
gmail_list_with_ai() {
    local ai_query="$1"
    local max_results="${2:-10}"
    
    log "Fetching emails for AI analysis: $ai_query"
    
    local response=$(google_api_call \
        "https://gmail.googleapis.com/gmail/v1/users/me/messages?maxResults=$max_results" \
        "GET" \
        "" \
        "true")
    
    local message_ids=$(echo "$response" | jq -r '.messages[]?.id')
    
    local email_summaries=""
    for msg_id in $message_ids; do
        local msg=$(google_api_call \
            "https://gmail.googleapis.com/gmail/v1/users/me/messages/$msg_id" \
            "GET" \
            "" \
            "true")
        
        local subject=$(echo "$msg" | jq -r '.payload.headers[] | select(.name=="Subject") | .value')
        local from=$(echo "$msg" | jq -r '.payload.headers[] | select(.name=="From") | .value')
        email_summaries+="ID: $msg_id | From: $from | Subject: $subject\n"
    done
    
    local ai_response=$(call_claude "$ai_query" "$email_summaries")
    echo "$ai_response"
}

# Google Drive: Upload file
drive_upload() {
    local file_path="$1"
    local mime_type="${2:-application/octet-stream}"
    
    [[ ! -f "$file_path" ]] && error "File not found: $file_path"
    
    log "Uploading file: $file_path"
    
    local filename=$(basename "$file_path")
    local metadata=$(jq -n --arg name "$filename" '{name: $name}')
    
    local response=$(curl -s -X POST \
        -H "Authorization: Bearer $GOOGLE_OAUTH_TOKEN" \
        -F "metadata=$metadata;type=application/json;charset=UTF-8" \
        -F "file=@$file_path;type=$mime_type" \
        "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart")
    
    if echo "$response" | jq -e '.id' > /dev/null; then
        local file_id=$(echo "$response" | jq -r '.id')
        success "File uploaded: $file_id"
        echo "$file_id"
    else
        error "Upload failed: $(echo "$response" | jq -r '.error.message // "Unknown error"')"
    fi
}

# Google Calendar: Create event with AI
calendar_create_event_ai() {
    local natural_language="$1"
    
    log "Creating calendar event from: $natural_language"
    
    local ai_prompt="Convert this to a Google Calendar API event JSON (only return valid JSON, no explanation):
    
    Request: $natural_language
    
    Return format:
    {
      \"summary\": \"Event title\",
      \"description\": \"Event description\",
      \"start\": {\"dateTime\": \"2025-11-01T10:00:00-07:00\"},
      \"end\": {\"dateTime\": \"2025-11-01T11:00:00-07:00\"}
    }"
    
    local event_json=$(call_claude "$ai_prompt")
    
    local response=$(google_api_call \
        "https://www.googleapis.com/calendar/v3/calendars/primary/events" \
        "POST" \
        "$event_json" \
        "true")
    
    if echo "$response" | jq -e '.id' > /dev/null; then
        success "Event created: $(echo "$response" | jq -r '.summary')"
        echo "$response" | jq -r '.htmlLink'
    else
        error "Failed to create event: $(echo "$response" | jq -r '.error.message // "Unknown error"')"
    fi
}

# Google Sheets: AI-powered data operations
sheets_ai_operation() {
    local spreadsheet_id="$1"
    local operation="$2"
    
    log "Performing AI operation on spreadsheet: $spreadsheet_id"
    
    # Get sheet data
    local response=$(google_api_call \
        "https://sheets.googleapis.com/v4/spreadsheets/$spreadsheet_id/values/A1:Z1000" \
        "GET" \
        "" \
        "true")
    
    local sheet_data=$(echo "$response" | jq -c '.values')
    
    local ai_response=$(call_claude "$operation" "Spreadsheet data: $sheet_data")
    echo "$ai_response"
}

# Workflow automation engine
run_workflow() {
    local workflow_file="$1"
    
    [[ ! -f "$workflow_file" ]] && error "Workflow file not found: $workflow_file"
    
    log "Running workflow: $workflow_file"
    
    local workflow=$(cat "$workflow_file")
    local steps=$(echo "$workflow" | jq -c '.steps[]')
    
    while IFS= read -r step; do
        local action=$(echo "$step" | jq -r '.action')
        local params=$(echo "$step" | jq -r '.params')
        
        log "Executing step: $action"
        
        case "$action" in
            "gmail_send")
                local to=$(echo "$params" | jq -r '.to')
                local subject=$(echo "$params" | jq -r '.subject')
                local body=$(echo "$params" | jq -r '.body')
                gmail_send "$to" "$subject" "$body"
                ;;
            "drive_upload")
                local file=$(echo "$params" | jq -r '.file')
                drive_upload "$file"
                ;;
            "calendar_event")
                local description=$(echo "$params" | jq -r '.description')
                calendar_create_event_ai "$description"
                ;;
            "ai_process")
                local prompt=$(echo "$params" | jq -r '.prompt')
                local context=$(echo "$params" | jq -r '.context // ""')
                call_claude "$prompt" "$context"
                ;;
            *)
                warning "Unknown action: $action"
                ;;
        esac
    done <<< "$steps"
    
    success "Workflow completed"
}

# Main menu
show_menu() {
    cat <<EOF

Google API AI Automation
========================
1) Send Gmail
2) List & Analyze Emails (AI)
3) Upload to Drive
4) Create Calendar Event (AI)
5) Sheets AI Operation
6) Run Workflow
7) Exit

EOF
}

# Main function
main() {
    check_deps
    init_dirs
    
    if [[ $# -eq 0 ]]; then
        while true; do
            show_menu
            read -p "Choose option: " choice
            
            case $choice in
                1)
                    read -p "To: " to
                    read -p "Subject: " subject
                    read -p "Body: " body
                    gmail_send "$to" "$subject" "$body"
                    ;;
                2)
                    read -p "AI Query (e.g., 'Find urgent emails'): " query
                    gmail_list_with_ai "$query"
                    ;;
                3)
                    read -p "File path: " file
                    drive_upload "$file"
                    ;;
                4)
                    read -p "Event description: " desc
                    calendar_create_event_ai "$desc"
                    ;;
                5)
                    read -p "Spreadsheet ID: " sheet_id
                    read -p "Operation: " operation
                    sheets_ai_operation "$sheet_id" "$operation"
                    ;;
                6)
                    read -p "Workflow file: " workflow
                    run_workflow "$workflow"
                    ;;
                7)
                    exit 0
                    ;;
                *)
                    warning "Invalid option"
                    ;;
            esac
        done
    else
        # Command-line mode
        case "$1" in
            gmail-send)
                gmail_send "$2" "$3" "$4"
                ;;
            gmail-analyze)
                gmail_list_with_ai "$2"
                ;;
            drive-upload)
                drive_upload "$2"
                ;;
            calendar-create)
                calendar_create_event_ai "$2"
                ;;
            sheets-ai)
                sheets_ai_operation "$2" "$3"
                ;;
            workflow)
                run_workflow "$2"
                ;;
            *)
                error "Unknown command: $1"
                ;;
        esac
    fi
}

main "$@"
