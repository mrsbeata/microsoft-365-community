# Proposal: Automation System for Community Calls

## Vision

Create an automated system that:
- Maintains community call resources without manual intervention
- Updates metadata automatically
- Generates summaries and transcripts
- Ensures content quality and completeness
- Provides AI agents with structured, accessible knowledge

## System Architecture

### Agent 1: Knowledge Agent (Main)
**Purpose**: Contains all knowledge about MM4M365
- Trained on all competency articles
- Trained on all practical scenarios
- Trained on all community call content
- Can answer questions, provide guidance, suggest resources

### Agent 2: Content Maintenance Agent
**Purpose**: Keeps content healthy and up-to-date
- Checks for broken links
- Validates markdown formatting
- Ensures cross-references are correct
- Monitors file structure
- Alerts on missing metadata

### Agent 3: Community Call Processor
**Purpose**: Automatically processes new community calls
- Watches for new YouTube videos (via API or webhook)
- Downloads/processes presentation files
- Generates AI summaries
- Creates transcript summaries
- Updates index.md automatically
- Creates new call .md file with metadata

### Agent 4: Link Manager
**Purpose**: Manages all links and cross-references
- Validates internal links
- Updates cross-references when articles change
- Maintains "Related documents" sections
- Checks external links (YouTube, etc.)

### Agent 5: Summary Generator
**Purpose**: Generates summaries and extracts key points
- Summarizes community call transcripts
- Extracts key takeaways
- Identifies related competencies
- Generates tags and topics

## Automation Workflow

### When New Community Call is Published

1. **Detection** (Agent 3)
   - Monitors YouTube channel for new videos
   - Or receives webhook/notification
   - Identifies call metadata (date, topic, speakers)

2. **Content Processing** (Agent 3)
   - Downloads presentation from SharePoint (if available)
   - Converts PPT to PDF
   - Extracts key slides as PNG
   - Downloads/processes transcript (if available)

3. **Summary Generation** (Agent 5)
   - Generates call summary
   - Extracts key takeaways
   - Identifies related competencies
   - Tags content appropriately

4. **File Creation** (Agent 3)
   - Creates new .md file with template
   - Populates metadata
   - Links to resources
   - Places files in correct structure

5. **Index Update** (Agent 3)
   - Updates index.md table
   - Maintains chronological order
   - Ensures all links work

6. **Quality Check** (Agent 2)
   - Validates markdown syntax
   - Checks all links
   - Verifies file structure
   - Ensures metadata completeness

7. **Cross-Reference Update** (Agent 4)
   - Updates related competency articles
   - Adds links in "Related documents" sections
   - Maintains bidirectional links

### Ongoing Maintenance

**Daily/Weekly:**
- Agent 2: Content health checks
- Agent 4: Link validation
- Agent 2: Format validation

**Monthly:**
- Agent 5: Review and improve summaries
- Agent 1: Update knowledge base with new content
- Agent 2: Comprehensive content audit

## Implementation Options

### Option 1: GitHub Actions
- Automated workflows on schedule
- Can monitor YouTube API
- Can process files and create PRs
- Runs in GitHub environment

### Option 2: Azure Functions/Logic Apps
- Serverless automation
- Can integrate with SharePoint
- Can process files
- Can trigger on events

### Option 3: Custom Agent System
- Dedicated AI agents for each task
- Can use OpenAI/Claude APIs
- More flexible but requires hosting

## Data Sources

1. **YouTube API**: Monitor for new videos
2. **SharePoint**: Download presentations (one-time migration, then store in GitHub)
3. **Transcripts**: YouTube auto-transcripts or manual uploads
4. **GitHub**: Store all processed content

## Benefits

1. **Zero Manual Work**: Once set up, runs automatically
2. **Consistency**: All calls follow same structure
3. **Completeness**: Nothing gets missed
4. **Quality**: Automated validation ensures standards
5. **AI-Ready**: Structured data perfect for AI agents
6. **Scalable**: Handles any number of calls

## Success Metrics

- Time to process new call: < 1 hour
- Link accuracy: > 99%
- Content completeness: 100%
- Zero manual intervention needed
- AI agent can answer questions about all calls

## Next Steps

1. Get core team approval
2. Design detailed agent specifications
3. Choose implementation platform
4. Build MVP for one call
5. Test and refine
6. Roll out full automation

