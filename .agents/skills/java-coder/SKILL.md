---
name: java-coder
description: Java/Spring Boot coding standards and preferences. Load this skill whenever writing, reviewing, or refactoring Java or Spring Boot code to ensure consistent style and architecture.
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# Java Coding Standards

These are non-negotiable standards. Apply them to every piece of Java or Spring Boot code you write or modify.

## General

- **Favor readability over cleverness** — write for the next person who reads this code
- **Comment only complex or non-obvious logic** — never restate what the code already expresses
- **Choose names that reveal intent** for variables, methods, and classes
  - Exception: catch-block variables should be a single character (e.g., `catch (Exception e)`)
- **Follow established language and project conventions**

---

### Imports

- Always prefer simple class names over fully qualified names — add an import instead:
  - ✅ `ClassName` | ❌ `com.package.ClassName` *(unless the name conflicts with another import)*
- Always use **static imports** for utility methods, including but not limited to:
  - `Collections.emptyList()`, `Collections.emptyMap()`, `Collections.emptySet()`
  - `Collectors.toList()`, `Collectors.toSet()`, `Collectors.joining()`

---

### Collections & Optionals

- Prefer empty-collection factory methods over `List/Map/Set.of()` for empty collections:
  - ✅ `emptyList()`, `emptyMap()`, `emptySet()`
- Never use `Optional` as a method parameter or class field — it is **exclusively a return type**

---

### Code Style

- **Always wrap statement bodies in braces**, even for single-line blocks
- Prefer `String.formatted(...)` over `+` string concatenation
- Prefer **stream-based functional iteration** over `for`/`while` loops
- Prefer the **ternary operator** or a **`switch` expression** over `if` statements where it improves clarity

---

### `var` Usage

`var` is allowed **only when the inferred type is immediately and unambiguously clear**:

| ✅ Allowed | ❌ Disallowed |
|---|---|
| Constructor calls: `var foo = new Foo();` | Complex or chained expressions |
| Builder calls: `var bar = Bar.builder().build();` | Method return values where the type is not obvious |

- `var` is **freely allowed in tests** at the author's discretion

---

### Sensitive Data & `record` Classes

- **Always override `toString`** in `record` classes to prevent sensitive fields from leaking into logs
  - Fields to mask include (but are not limited to): `password`, `ssn`, `apiKey`, `clientSecret`, `secretKey`

---

### Method Formatting

- Keep method declarations and invocations on a **single line** when they fit reasonably
- When a method has multiple arguments and the line becomes too long or hard to read, **format each argument on its own line** with the closing parenthesis on a separate line — except for lambda blocks, where `})` should remain on the same line:

```java
// ✅ Multi-line when needed
someMethod(
    firstArgument,
    secondArgument,
    thirdArgument
);

someMethodWithLambda(e -> {
    // ...
}); // ✅ should remain on the same line

// ✅ Single line when it fits
someMethod(firstArgument, secondArgument);


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

## Testing

**Assertions**
- Always use AssertJ — never raw JUnit assertions

**Naming**
- Test methods: `{methodName}_{precondition}_{expectedOutcome}`
- `@DisplayName`: human-readable sentence describing the scenario; never echo the method name
- The instance of the class under test: always `subject`

**Structure**
- Prefer `@InjectMocks` over constructing the tested class manually in `@BeforeEach`
- Prefer `var` for locals initialized by a constructor or builder call
- Extract expected values into named constants only when they appear in multiple test cases; inline single-use values

**Scope**
- Only test business logic and services — never write tests for JPA/Hibernate entities, DTOs, `@Configuration` beans, or Spring Data repositories

## Security

- Never hardcode credentials, secrets, or tokens — always externalise them via environment variables or a secrets manager
- Validate and sanitize all user input at system boundaries; trust nothing from the outside
- Apply OWASP best practices by default — injection, broken access control, and insecure design are never acceptable
- Keep security concerns consistent across the stack; a secure API means nothing if the service layer bypasses it
