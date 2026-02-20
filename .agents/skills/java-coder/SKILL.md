---
name: java-coder
description: Java/Spring Boot coding standards and preferences. Load this skill whenever writing, reviewing, or refactoring Java or Spring Boot code to ensure consistent style and architecture.
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# Java Coding Standards

These are non-negotiable standards. Apply them to every piece of Java or Spring Boot code you write or modify.

## General

- Favor readability over cleverness — the next person reading this code matters
- Only comment complex or non-obvious logic; never state what the code already says
- Choose names that reveal intent for variables, methods, and classes
- Follow the established conventions of the language and the project

## Tech Stack

| Concern       | Choice                                                              |
|---------------|---------------------------------------------------------------------|
| Language      | Java 21+ — use modern features (records, sealed classes, patterns) |
| Framework     | Spring Boot — match the project version; follow Spring idioms      |
| Build         | Maven (preferred) or Gradle                                        |
| Persistence   | JPA/Hibernate · PostgreSQL · H2 (tests)                            |
| Testing       | JUnit 5 · Mockito                                                  |

## Spring Boot Rules

**Dependency Injection**
- Always use constructor injection — never field injection (`@Autowired` on fields)

**Architecture**
- Enforce the layered boundary: `Controller → Service → Repository`
- Never let repositories leak into controllers, or business logic leak into controllers

**API Design**
- Follow RESTful conventions for endpoint naming, HTTP methods, and status codes
- Use DTOs for all request/response payloads — keep them separate from JPA entities
- Default to Java records for DTOs; only use classes when mutability is required

**Error Handling & Validation**
- Centralize exception handling with `@ControllerAdvice`
- Declare constraints with Bean Validation annotations (`@NotNull`, `@Size`, etc.)
- Return `Optional<T>` from methods that may produce no result; avoid returning `null`

**Code Style**
- Prefer streams and functional pipelines over imperative loops, when it reads clearly

**Lombok**
- Use it to reduce boilerplate, not to hide design — keep the intent visible
- Protect sensitive fields from accidental logging: add `@ToString.Exclude` to `password`, `ssn`, `apiKey`, `clientSecret`, `secretKey`, and similar
- On `@Data` JPA entities, always pair with `@NoArgsConstructor` and `@AllArgsConstructor`
- Use `@Builder` for complex object construction (especially test data); add it to any DTO with more than 3 fields
- Use `@Slf4j` for logging — `System.out.println()` is never acceptable in production code

## Formatting

Resolve formatting rules in this order — stop at the first match:

1. **`.editorconfig`** — if present at the project root, it takes precedence for indent style, indent size, line endings, and charset
2. **IDE code style settings** — check for exported scheme files:
   - IntelliJ IDEA (preferred): `.idea/codeStyles/`, `*.xml` schemes, or `Project.xml`
   - Eclipse: `.settings/org.eclipse.jdt.core.prefs` or a `.xml` formatter profile
3. **Infer from the codebase** — when neither of the above exists, read several existing source files and match their conventions exactly (indentation, brace style, import ordering, line length, etc.)

Never impose personal formatting preferences. The goal is consistency with what is already there.

## Security

- Never hardcode credentials, secrets, or tokens — always externalise them via environment variables or a secrets manager
- Validate and sanitize all user input at system boundaries; trust nothing from the outside
- Apply OWASP best practices by default — injection, broken access control, and insecure design are never acceptable
- Keep security concerns consistent across the stack; a secure API means nothing if the service layer bypasses it
