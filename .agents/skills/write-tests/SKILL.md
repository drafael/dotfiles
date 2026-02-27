---
name: write-tests
description: Write unit and integration tests for code. Use when the user asks to "write tests", "add tests", "add test coverage", or "create test cases" for functions, services, or components.
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# Write Tests

Write unit and integration tests: **$ARGUMENTS**

## Process

Follow these steps in order:

1. **Understand the project's test conventions**
   - Identify the testing framework (JUnit, Jest, PyTest, RSpec, etc.)
   - Load the reference file that matches the detected framework (if exists) to learn the naming, structure, and assertion style:
      - `references/junit.md`
      - `references/jest.md`
      - `references/pytest.md`
      - `references/rspec.md`
   - Read existing tests to learn the project's naming, structure, and assertion style
   - Check test configuration and setup files

2. **Analyse the code under test**
   - Identify the public interface and critical business logic
   - Map dependencies and external interactions
   - Note error conditions, edge cases, and validation rules
   - Target >80% line and branch coverage; identify gaps before writing

3. **Plan the test strategy**
   - Decide which levels are needed: unit, integration, end-to-end
   - List what to mock or stub, and why
   - Prioritise business-critical paths first

4. **Write unit tests**
   - Test each function or method in isolation
   - Cover: happy path → edge cases → boundary conditions → error/exception paths
   - Follow the AAA pattern (Arrange / Act / Assert) — use blank lines to separate phases, never write `// Arrange` comments
   - Use descriptive test names that explain the scenario being tested
   - Keep each test focused on one behaviour; avoid assertions on unrelated state

5. **Write integration tests**
   - Test real interactions between components: APIs, databases, external services
   - Verify data flow end-to-end across layer boundaries
   - Cover failure modes and partial failures, not just the happy path

6. **Mocking and test data**
   - Mock external dependencies to keep unit tests fast and deterministic
   - Avoid over-mocking — if a mock replicates production logic, use a real object instead
   - Use factories or builders for complex test data; keep setup out of assertion code
   - Ensure tests are isolated — no shared mutable state between cases

7. **Apply applicable specialist concerns**
   - **Async code**: use the framework's async test utilities; test both resolution and rejection
   - **Security**: cover auth checks, input validation, and access control boundaries
   - **UI**: test rendered output, keyboard navigation, and ARIA semantics where relevant
