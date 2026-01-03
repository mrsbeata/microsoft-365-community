# Proposal: Community Calls Resource Structure

## Purpose

Create a comprehensive, AI-agent-friendly structure for storing and accessing all community call resources (presentations, recordings, transcripts) that:
- Is independent of external systems (no SharePoint dependencies)
- Requires no authentication to access
- Is stable and long-term
- Is not person-dependent
- Can be directly read by AI agents

## Proposed Structure

```
Community/
  community-calls/
    index.md (overview table of all calls)
    README.md (how to use this resource)
    2025/
      2025-01-15-copilot-implementation.md
      2025-02-20-content-management.md
      presentations/
        2025-01-15-copilot-implementation.pdf
        2025-01-15-copilot-implementation-slides/
          slide-1-overview.png
          slide-2-key-points.png
          slide-3-summary.png
```

## Metadata Template

Each community call gets a `.md` file with:

```markdown
---
title: Community Call - [Topic]
date: YYYY-MM-DD
speakers: [Name1, Name2]
topics: [topic1, topic2]
competencies: [Competency1, Competency2]
youtube_url: https://youtube.com/...
youtube_channel: https://youtube.com/channel/...
---

## Summary
[AI-generated summary of key points]

## Transcript Summary
[AI-generated summary of transcript]

## Key Takeaways
- Point 1
- Point 2
- Point 3

## Related Competencies
- [Competency Name](link-to-competency.md)

## Resources
- [Full Presentation PDF](presentations/YYYY-MM-DD-topic.pdf)
- [Key Slides](presentations/YYYY-MM-DD-topic-slides/)
- [YouTube Recording](youtube-url)
- [Transcript](transcripts/YYYY-MM-DD-topic-transcript.md) (if available)
```

## Index Table Structure

The `index.md` will contain a searchable table:

| Date | Topic | Speakers | Competencies | Resources |
|------|-------|----------|--------------|-----------|
| 2025-01-15 | Copilot Implementation | Pia Langenkrans, Simon Hudson | Staff & Training, AI & Cognitive Business | [View](2025/2025-01-15-copilot-implementation.md) |
| 2025-02-20 | Content Management | ... | Management of Content | [View](2025/2025-02-20-content-management.md) |

## File Guidelines

### PDF Presentations
- Store full presentation as PDF (smaller than PPT, AI-readable)
- Filename: `YYYY-MM-DD-topic.pdf`
- Place in `presentations/` folder

### Key Slides (PNG)
- Export 5-10 most important slides as PNG
- Filename: `slide-N-description.png`
- Place in `presentations/YYYY-MM-DD-topic-slides/`
- Used for inline viewing in MS Learn

### Transcripts (optional)
- AI-generated or manual transcripts
- Markdown format for easy reading
- Place in `transcripts/` folder

## Benefits

1. **AI Agent Friendly**: All content directly accessible, no authentication needed
2. **Stable**: Not dependent on external systems or individuals
3. **Searchable**: Markdown files are easily searchable
4. **Complete**: All resources in one place
5. **Long-term**: GitHub provides permanent storage

## Size Considerations

- Estimated: 50 calls × 5 MB PDF = ~250 MB
- PNG slides: ~50 MB total
- Total: ~300 MB (well within GitHub limits)
- MS Learn impact: Minimal (markdown files are small)

## Next Steps

1. Get approval from core team
2. Create initial structure
3. Migrate existing community calls
4. Set up automation for new calls

