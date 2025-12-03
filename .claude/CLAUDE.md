# Personal Claude Preferences

## Communication Style
- Be concise but thorough in explanations
- Use examples when explaining concepts
- Ask clarifying questions when requirements are ambiguous
- Provide step-by-step instructions for complex tasks

## Code Preferences

### General
- Prioritize readability over clever solutions
- Never write comments for obvious code
- Include comments only for complex logic
- Use meaningful variable and function names
- Follow established conventions for each language

### Primary Stack
- **Java**: Prefer Java 21+ features, use modern APIs and language constructs
- **Spring Boot**: Use current project/codebase version (preferably), or latest stable version, follow Spring best practices
- **Build Tools**: Maven or Gradle (prefer Maven for consistency)
- **Database**: JPA/Hibernate, PostgreSQL, H2
- **Testing**: JUnit 5, Mockito

### Java/Spring Boot Specific
- Always use constructor injection over field injection
- Follow layered architecture: Controller → Service → Repository
- Use DTOs for API requests/responses, separate from entities
- Use Java records for DTOs unless otherwise specified
- Implement proper exception handling with `@ControllerAdvice`
- Add validation using Bean Validation annotations
- Use Optional appropriately for nullable returns
- Prefer streams over traditional loops when readable
- Use Lombok judiciously (`@Data`, `@Builder`, `@Slf4j`)
  * Avoid overusing Lombok to the point of obscuring code clarity
  * Add `@ToString.Exclude` to sensitive fields like: `password`, `ssn`, `apiKey`, `clientSecret`, `secretKey`, etc.
  * Always include `@NoArgsConstructor` and `@AllArgsConstructor` when using `@Data` on JPA entities
  * Use `@Builder` for complex object creation, especially in tests
  * Always add `@Builder` to DTOs when they have more than 3 fields
  * Use `@Slf4j` for logging, avoid using `System.out.println()`
- Follow RESTful conventions for API endpoints

## Security Considerations
- Never hardcode sensitive information
- Use environment variables for configuration
- Validate and sanitize user inputs
- Follow security best practices for each technology
