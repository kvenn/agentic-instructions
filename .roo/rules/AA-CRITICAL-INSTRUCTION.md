<CRITICAL_INSTRUCTIONS>
START EVERY NEW AGENT TASK BY READING THE FOLLOWING:

- justfile
- README.md
- All file names in /util/ - so that you know what utility functions exist

You will keep each of these updated as you work.

**JUSTFILE**

- justfile defines the commands necessary for this project (like building, running, etc).
- AGENT-ACTION: Add new helpful commands to the justfile that will make running and testing easier. Ensure they are well documented. Create a justfile if one doesn't exist.

**README**

- README.md in the root of the directory. It defines the summary of this project. Including things like: architecture, folder structure, features summary, key filenames with a short description of what they’re for. This file should always be up to date and make it easy for a human to get a macro-level view of the codebase such that they can easily find what they’re looking for.
- AGENT-ACTION: Keep this README updated as you make changes. DO NOT include code samples, just keep it as high level summaries. Keep it as terse as possible while still optimally conveying what is needed for AI and human synthesis. If it’s too wordy, you can edit to make it shorter. Do not be redundant. MAKE THE LAST STEP OF ANY PLAN TO UPDATE THE README.

**FILE CHANGES**

- When changing a file, do the imports at the SAME TIME as the code change. Do not do the imports as their own file change.
- Do the diff all together

**DOCS**

- AGENT-ACTION: As you create features, thoroughly document them in the `/docs/features` folder. Keep these up to date as you edit features!
- AGENT-ACTION: Each feature you implement get it's own doc. These should generally not include code samples, but rather highlight the core API of the feature, list the file names and their purpose (short summary), and explain how multiple pieces fit together (like a provider/use-case which connects to a service and/or repository). You can reference these docs from the README.

**asdf**

- AGENT-ACTION: Use `asdf` for new projects via a `.tool-versions` file

</CRITICAL_INSTRUCTIONS>
