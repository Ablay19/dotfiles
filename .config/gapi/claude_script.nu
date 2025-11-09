# Google API AI Automation Script for Nushell
# Requires: Nushell 0.80+

# Configuration
const CONFIG_DIR = ($env.HOME | path join ".google-api-ai")
const CACHE_DIR = ($CONFIG_DIR | path join "cache")
const LOG_FILE = ($CONFIG_DIR | path join "automation.log")

# Initialize environment
def init-env [] {
    mkdir $CONFIG_DIR
    mkdir $CACHE_DIR
    touch $LOG_FILE
}

# Logging
def log [message: string, level: string = "INFO"] {
    let timestamp = (date now | format date "%Y-%m-%d %H:%M:%S")
    let log_entry = $"[($timestamp)] ($level): ($message)"
    print $log_entry
    echo $log_entry | save --append $LOG_FILE
}

# Call Claude AI
def call-claude [
    prompt: string
    --context: string = ""
] {
    let api_key = ($env.CLAUDE_API_KEY? | default "")
    
    if ($api_key | is-empty) {
        log "CLAUDE_API_KEY not set" "WARNING"
        return null
    }
    
    let full_prompt = if ($context | is-empty) {
        $prompt
    } else {
        $"Context: ($context)\n\nTask: ($prompt)"
    }
    
    let response = (http post https://api.anthropic.com/v1/messages
        --content-type "application/json"
        --headers [
            "x-api-key" $api_key
            "anthropic-version" "2023-06-01"
        ]
        {
            model: "claude-sonnet-4-20250514"
            max_tokens: 4096
            messages: [{
                role: "user"
                content: $full_prompt
            }]
        }
    )
    
    $response.content.0.text
}

# Google API call wrapper
def google-api [
    endpoint: string
    --method: string = "GET"
    --data: any = null
    --use-oauth: bool = false
] {
    let auth = if $use_oauth {
        let token = ($env.GOOGLE_OAUTH_TOKEN? | default "")
        if ($token | is-empty) {
            error make {msg: "GOOGLE_OAUTH_TOKEN not set"}
        }
        ["Authorization" $"Bearer ($token)"]
    } else {
        let key = ($env.GOOGLE_API_KEY? | default "")
        if ($key | is-empty) {
            error make {msg: "GOOGLE_API_KEY not set"}
        }
        []
    }
    
    let url = if $use_oauth {
        $endpoint
    } else {
        $"($endpoint)?key=($env.GOOGLE_API_KEY)"
    }
    
    let headers = if ($data != null) {
        $auth ++ [["Content-Type" "application/json"]]
    } else {
        $auth
    }
    
    if ($method == "GET") {
        http get $url --headers $headers
    } else if ($method == "POST") {
        http post $url --content-type "application/json" --headers $headers $data
    } else if ($method == "PUT") {
        http put $url --content-type "application/json" --headers $headers $data
    } else if ($method == "DELETE") {
        http delete $url --headers $headers
    }
}

# Gmail: Send email
def gmail-send [
    to: string
    subject: string
    body: string
] {
    log $"Sending email to: ($to)"
    
    let email_content = $"To: ($to)\nSubject: ($subject)\nContent-Type: text/html; charset=utf-8\n\n($body)"
    let email_raw = ($email_content | encode base64)
    
    let response = (google-api "https://gmail.googleapis.com/gmail/v1/users/me/messages/send"
        --method "POST"
        --data {raw: $email_raw}
        --use-oauth
    )
    
    if ($response.id? != null) {
        log $"Email sent successfully: ($response.id)" "SUCCESS"
        $response.id
    } else {
        log $"Failed to send email: ($response.error?.message? | default 'Unknown error')" "ERROR"
        null
    }
}

# Gmail: List and analyze emails with AI
def gmail-analyze [
    query: string
    --max-results: int = 10
] {
    log $"Fetching emails for AI analysis: ($query)"
    
    let messages = (google-api $"https://gmail.googleapis.com/gmail/v1/users/me/messages?maxResults=($max_results)"
        --use-oauth
    )
    
    let email_details = ($messages.messages? | default [] | each {|msg|
        let full_msg = (google-api $"https://gmail.googleapis.com/gmail/v1/users/me/messages/($msg.id)"
            --use-oauth
        )
        
        let subject = ($full_msg.payload.headers | where name == "Subject" | get value.0? | default "No subject")
        let from = ($full_msg.payload.headers | where name == "From" | get value.0? | default "Unknown")
        
        {
            id: $msg.id
            from: $from
            subject: $subject
        }
    })
    
    let context = ($email_details | to json)
    let ai_response = (call-claude $query --context $context)
    
    {
        emails: $email_details
        ai_analysis: $ai_response
    }
}

# Google Drive: Upload file
def drive-upload [
    file_path: string
    --mime-type: string = "application/octet-stream"
] {
    if not ($file_path | path exists) {
        error make {msg: $"File not found: ($file_path)"}
    }
    
    log $"Uploading file: ($file_path)"
    
    let filename = ($file_path | path basename)
    let file_content = (open --raw $file_path | encode base64)
    
    # Note: This is a simplified version. For real multipart upload, you'd need a more complex implementation
    let metadata = {name: $filename}
    
    let response = (google-api "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart"
        --method "POST"
        --data $metadata
        --use-oauth
    )
    
    if ($response.id? != null) {
        log $"File uploaded: ($response.id)" "SUCCESS"
        $response.id
    } else {
        log $"Upload failed: ($response.error?.message? | default 'Unknown error')" "ERROR"
        null
    }
}

# Google Calendar: Create event with AI
def calendar-create-ai [
    description: string
] {
    log $"Creating calendar event from: ($description)"
    
    let ai_prompt = $"Convert this to a Google Calendar API event JSON (only return valid JSON, no explanation):

Request: ($description)

Return format:
{
  \"summary\": \"Event title\",
  \"description\": \"Event description\",
  \"start\": {\"dateTime\": \"2025-11-01T10:00:00-07:00\"},
  \"end\": {\"dateTime\": \"2025-11-01T11:00:00-07:00\"}
}"
    
    let event_json_str = (call-claude $ai_prompt)
    let event_data = ($event_json_str | from json)
    
    let response = (google-api "https://www.googleapis.com/calendar/v3/calendars/primary/events"
        --method "POST"
        --data $event_data
        --use-oauth
    )
    
    if ($response.id? != null) {
        log $"Event created: ($response.summary?)" "SUCCESS"
        $response.htmlLink?
    } else {
        log $"Failed to create event: ($response.error?.message? | default 'Unknown error')" "ERROR"
        null
    }
}

# Google Sheets: AI-powered operations
def sheets-ai [
    spreadsheet_id: string
    operation: string
] {
    log $"Performing AI operation on spreadsheet: ($spreadsheet_id)"
    
    let sheet_data = (google-api $"https://sheets.googleapis.com/v4/spreadsheets/($spreadsheet_id)/values/A1:Z1000"
        --use-oauth
    )
    
    let context = ($sheet_data | to json)
    let ai_response = (call-claude $operation --context $"Spreadsheet data: ($context)")
    
    {
        data: $sheet_data
        ai_analysis: $ai_response
    }
}

# Workflow automation engine
def run-workflow [
    workflow_file: string
] {
    if not ($workflow_file | path exists) {
        error make {msg: $"Workflow file not found: ($workflow_file)"}
    }
    
    log $"Running workflow: ($workflow_file)"
    
    let workflow = (open $workflow_file | from json)
    
    $workflow.steps | each {|step|
        log $"Executing step: ($step.action)"
        
        match $step.action {
            "gmail_send" => {
                gmail-send $step.params.to $step.params.subject $step.params.body
            },
            "drive_upload" => {
                drive-upload $step.params.file
            },
            "calendar_event" => {
                calendar-create-ai $step.params.description
            },
            "ai_process" => {
                call-claude $step.params.prompt --context ($step.params.context? | default "")
            },
            _ => {
                log $"Unknown action: ($step.action)" "WARNING"
            }
        }
    }
    
    log "Workflow completed" "SUCCESS"
}

# Interactive menu
def main [] {
    init-env
    
    print "\nGoogle API AI Automation (Nushell)"
    print "===================================="
    print "Commands available:"
    print "  gmail-send <to> <subject> <body>"
    print "  gmail-analyze <query>"
    print "  drive-upload <file>"
    print "  calendar-create <description>"
    print "  sheets-ai <spreadsheet_id> <operation>"
    print "  run-workflow <workflow_file>"
    print ""
}

# Export commands
export def "gmail send" [to: string, subject: string, body: string] {
    gmail-send $to $subject $body
}

export def "gmail analyze" [query: string, --max: int = 10] {
    gmail-analyze $query --max-results $max
}

export def "drive upload" [file: string] {
    drive-upload $file
}

export def "calendar create" [description: string] {
    calendar-create-ai $description
}

export def "sheets analyze" [spreadsheet_id: string, operation: string] {
    sheets-ai $spreadsheet_id $operation
}

export def "workflow run" [file: string] {
    run-workflow $file
}

# Example workflow generator
def generate-example-workflow [] {
    let workflow = {
        name: "Daily automation"
        steps: [
            {
                action: "gmail_send"
                params: {
                    to: "example@email.com"
                    subject: "Automated Report"
                    body: "This is an automated message"
                }
            }
            {
                action: "ai_process"
                params: {
                    prompt: "Summarize today's tasks"
                    context: "Calendar events and emails"
                }
            }
        ]
    }
    
    $workflow | to json | save example-workflow.json
    log "Example workflow saved to example-workflow.json" "SUCCESS"
}
