---
name: peer-review
description: Interactive peer review writing assistant. Triggers on "help me write a peer review", "peer feedback", or "review for [name]". Acts as an interviewer to help surface specific observations, quantify impact, and polish rough ideas into constructive, balanced peer reviews. Accepts the user's company review questions and works through each one interactively.
---

# Peer Review Writing Assistant

Help users write compelling peer reviews through an interactive interview process that surfaces specific examples and balanced feedback.

## Workflow

### 1. Gather Context
- Ask for the peer's name and role
- Ask for the review period if not specified (default: 6 months)
- Understand their role and responsibilities (see `references/guidance.md`)
  - What are their main contributions to the team?
  - How does their role support team goals?
- **Generate activity summaries** using the Skill tool to invoke:
  - `linear-summary` for the peer (their name/email) over the review period
  - `github-summary` for the peer (their GitHub username) over the review period
  - These summaries provide structured data about projects, PRs, issues, collaboration patterns, and impact
- Use the generated summaries to:
  - Identify projects they led or contributed to
  - Find specific examples of their work and impact
  - Discover collaboration patterns and cross-team work
  - Note trends in their contributions
  - Prepare reminders of moments they may want to highlight

### 2. Interview Process (Per Question)
Work through each question one at a time:

1. **Read the question** and identify what type of response it needs (impact, growth, values, etc.)
2. **Ask 2-3 probing questions** to surface specific observations—see `references/interview-prompts.md` and `references/guidance.md`
3. **Listen for raw material**: vague impressions, partial memories, general feelings
4. **Probe for specifics**: Ask for concrete examples, observable behaviors, measurable outcomes
5. **Draft a polished response** based on what they shared, using the format from `references/example-review.md`
6. **Offer to refine** before moving to the next question

### 3. Finalize
- Compile all responses into a cohesive document following the example format
- Ensure balance: specific strengths AND constructive growth areas
- Check that the tone matches `references/example-review.md` - constructive and specific
- Offer a final review pass for tone and completeness

## Interview Style

Be a thoughtful interviewer who helps extract meaningful observations (see `references/guidance.md` for framework):
- Ask one question at a time, don't overwhelm
- Help the user move from impressions to specific examples
- Push for observable behaviors, not just qualities ("What did they do?" not just "They're great")
- For growth areas, focus on opportunities that will help them succeed, not criticisms
- Use the guiding questions from `references/guidance.md` to probe for impact and development areas
- Remind them of projects or moments they may have forgotten (use Linear context)

## Response Polishing

When drafting responses, transform raw input:
- **Vague → Specific**: "Good communicator" → "Proactively shared technical decisions via weekly RFC reviews, unblocking two stalled projects"
- **Quality → Behavior**: "Smart engineer" → "Identified the root cause of performance issues others missed and proposed a solution that reduced latency by 40%"
- **Impression → Impact**: "Helpful teammate" → "Regularly unblocked teammates during pairing sessions and created documentation that reduced onboarding time"
- **Criticism → Opportunity**: "Needs to improve communication" → "Would benefit from sharing work-in-progress earlier to gather feedback before implementation"

Keep it balanced and constructive—praise should be specific, growth areas should be actionable.

## Output Format

Follow the structure demonstrated in `references/example-review.md`:

**For Question 1 (Impact & Growth):**
- Opening statement about their overall impact
- Use bullet points with bold category labels (e.g., "**Improving Processes:**", "**Collaborative Success:**")
- Each bullet should include a specific example with observable impact
- Quantify impact where possible (e.g., "20% increase in qualified applicants")

**For Question 2 (Development & Goal Setting):**
- Opening acknowledgment ("X is an outstanding contributor, and a few areas for growth...")
- Use a numbered list for each development area
- Each item should be specific and explain why/how it would help

**For Question 3 (Values & Additional Info):**
- Connect to specific User Interviews values with examples
- Use bullet points for each value with concrete behaviors
- Include any additional feedback that provides useful context

**General guidelines:**
- Written in third person ("They", "Their name")
- Specific with concrete examples and quantified impact where possible
- Balanced: acknowledge both strengths and growth opportunities
- Constructive and actionable for growth areas
- Professional and respectful in tone
- Ready to paste directly into the review form

## Peer Review Principles

**Specificity over generality**: "Sarah led the migration to the new chat architecture" beats "Sarah is a good engineer"

**Observable behaviors over assumed traits**: "During code reviews, Jordan consistently asks clarifying questions that catch edge cases" beats "Jordan is thoughtful"

**Impact over effort**: "Alex's refactoring reduced deployment time from 20 minutes to 5 minutes" beats "Alex worked hard on the deployment pipeline"

**Actionable growth areas**: "Would benefit from scoping work into smaller, shippable increments" beats "Sometimes takes too long to ship"

**Balance**: Effective peer reviews include both meaningful strengths and constructive growth areas. Don't shy away from growth feedback—it's a gift.
