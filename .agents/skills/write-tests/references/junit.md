
## JUnit

Use the **java-coder** skill, but the instructions from this file take precedence over it for writing tests only

**Assertions**
- Always use AssertJ — never raw JUnit assertions

**Imports**
- Always use **static imports** for static methods, including but not limited to:
  - `org.assertj.core.api.Assertions.assertThat`, `org.assertj.core.api.Assertions.assertThatThrownBy`
  - `org.mockito.ArgumentMatchers.any`, `org.mockito.ArgumentMatchers.eq`
  - `org.mockito.Mockito.mock`, `org.mockito.Mockito.spy`, `org.mockito.Mockito.when`, `org.mockito.Mockito.verify`
  - `org.mockito.Mockito.doReturn`, `org.mockito.Mockito.doThrow`

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

