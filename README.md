# Agentic Instructions

This repo illustrations how I've been leveraging guidelines and specs to produce better output for agentic side projects. It includes files that can be copy/pasted directly into a new project.

## Overview

### Setup

When starting a new project, I run a script (ex: `sync-instrunctions flutter`) that copies (or syncs) all necessary files from this repo to the one I'm in.

### Core Files

**AGENTS.md and styleguide.md**

- `.roo/rules` holds all the core "base" instructions for the project
- We point the other agents at this folder (`AGENTS.md` is Codex's default, `.gemini/styleguide.md` is Gemini)

**`AA-CRITICAL_INSTRUCTION.md`**

This doc enforces a few key principles.

1. Updating the `README` as it goes (basically a compact "memory" that makes future agent runs much more efficient at finding / following rules)
2. [`justfile`](https://github.com/casey/just)
   1. Like a "makefile" or commands section of package.json. `just` works the same on any project with any language and is hot hot hot. If the AI has a set of commands it can run on a repo, it's so much better (for running, testing, deploying, scripts, anything).
3. `/docs/features`
   1. Keep a log of feature specs. Useful mostly for humans, but also for making big changes to a feature
4. Bonus
   1. Telling it other simple workflow rules, like check `/utils/` (as to not create the same thing 10 times) or do imports in the same edit as othe file changes
   2. `asdf` - another standard across languages for pinning framework/language versions. May override with `uv` for python, etc.

**`general.md`**

Just a bunch of core coding principles I personally use across any project. These work regardless of language. Customize to your liking.

**`flutter.md`**

I'll add language specific rules in here. I'll also include a recent changelog so it knows the most up-to-date APIs to use.

Some of these can be moved into general.

### New Project Phase

1. Author a product spec in ChatGPT 5.2 thinking. Basically tell it the project and that you want a product spec. Have it produce a markdown file.
2. Tell it to look at `docs/example-files` (if you have them) and follow those for how it architects / creates its first set of files
3. Let it rip.

### Example Files

- A bunch of files copied from a previous project that I thought was architected well. AI does very well when it has patterns already visible in the repo. You just need ONE feature you think is well architected and it'll follow it for all future ones.
- Eventually I want this to be a library / repo. It's just a bunch of highly opinionated architecture things. But I always iterate on it within the project and the AI is good enough at just taking it and building on it.

### TODO - other stuff

- Include docs on workflow (AI authors first one-shot pass, have codex and copilot review the PR, then I review the reviewed PR)
  - I select which model I use based on [this](https://artificialanalysis.ai/models?models=gpt-5-mini,o3,gpt-5-2,gpt-5-1-codex,gpt-5-2-codex,gpt-5-2-medium,claude-4-5-sonnet-thinking,claude-4-5-haiku-reasoning,claude-opus-4-5,claude-4-5-sonnet,claude-opus-4-5-thinking,gpt-5-1,gpt-5,gpt-5-minimal,o3-pro,o4-mini,gpt-5-medium,gpt-5-low,gpt-5-codex,claude-4-sonnet-thinking,claude-3-7-sonnet,claude-4-1-opus,claude-4-opus,claude-4-opus-thinking,claude-4-1-opus-thinking,claude-3-7-sonnet-thinking,claude-4-sonnet&intelligence-comparison=intelligence-vs-price)
    - Specifically looking at "**Intelligence Index Comparisons**"
- Include scripts and git commands I use regularly in all projects
  - `git create-private-here`
  - `git pr-review #`
