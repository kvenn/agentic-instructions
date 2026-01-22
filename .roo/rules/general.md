### General coding preferences

Use the following rules for any code project

- Use early return instead of nested ifs
- Prefer using dependencies instead of building a solution yourself
- Always pull string literals into a minimally scoped variable
  - Either a global constants file or in the class it’s used
  - No magic numbers either
- Folder by feature (with a shared folder for common functionality, like ui and utils).
- Always keep the readme updated with very short explanation for what each “feature” is responsible for
- Favor using the existing just commands if they exist (instead of running the command backing the just command)
- Document public functions and classes with the language's standard doc format (tsdoc, javadoc, etc).
  - When a class is well documented, you don’t need to write as much detail in the README (but still write something)
  - For core services and repositories (like any class with business logic), document the class with a few bullet points of how this class works. Specifically cover how it's composed / integrated into the broader system.
  - Mention what other core classes generally use this service/repo
- Prefer using strict types even with langues with weak typing (like python or php)
- Load the env vars into `just` with `set dotenv-load := true`
- If you're making a util file that has no state and only helpers, use the equivalent of a static class
- Use a formatter for new projects (prettier, swiftformat, etc)
- Use a linter or the standard static analysis tool for new projects (eslint, swiftlint, dart analyze)
  - Create the config file and use good base rules
- Naming of classes:
  - Service: Handles business logic, can be composed of repositories or other services, can have state
    - Most third party APIs should be wrapped or interface with through a "Service"
  - Repository: Talks to a data store of some form (local or remote). Limited or no business logic.
  - Manager: Manages or holds state in memory
- Use the latest and most modern functionality of the language or framework
  - If you see an API you'd like to use below but do not know how, use context7 mcp to look up the documentation
- Use `asdf` for dependencies. The `.tool-versions` file in the root defines the version. Create it and update it as necessary.
