### Node coding preferences

Use the following preferences when working in a node project

- Typescript with strict types
  - If working with json, create a type for it. DO NOT let `any` into the ecosystem if it can be avoided.
- pnpm 10.11.0 - DO NOT use npm or yarn
  - Run pnpm exec <command> instead of npx
- Nodemon for local dev
- For running typescript files, use tsx with a typecheck (like the following)

  ```
  // package.json
  "scripts": {
      "build": "tsc",
      "typecheck": "tsc --noEmit",
      "lint": "eslint . --ext .ts",
      "format": "prettier --write \"**/*.{ts,json,md}\"",
  }
  // justfile
  typecheck:
      pnpm typecheck

  # Run the Reddit content archiver
  myScript *args: typecheck
      pnpm exec tsx src/script.ts {{args}}
  ```

- dotenv - use for access dontenv in runtime. Make sure to source it in any entry-point scripts.
  - Use a config object with strong types that wraps the env.
- prettier
  - no semicolons
- eslint
  - Warn on `any`
  - eslint.config.js
- Node 24.0.0
  - Use `.js` in the import paths
- ES Modules (not commonjs - unless required by a core dependency)
- Prisma 6.8.2 (https://www.prisma.io/blog/prisma-orm-6-6-0-esm-support-d1-migrations-and-prisma-mcp-server)
  ```
  // prisma/schema.prisma
  generator client {
  provider = "prisma-client" // no `-js` at the end
  output = "../src/generated/prisma" // `output` is required
  moduleFormat = "esm" // or `"cjs"` for CommonJS
  }
  ```
  - AND
  - Usage in files: `import { PrismaClient } from './generated/prisma/client'`
- Favor using the latest ES and nodejs features
- Pino for logging with wrapping “Logger” class we define (don’t use console.log directly)
- Always use relative imports so they work correctly when tsc puts them in dist
