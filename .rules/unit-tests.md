# Unit Testing Guidelines for ActiveGenie

## Mocking Strategy
- **Mock external dependencies only**: Mock external services, APIs, and HTTP requests, but avoid mocking internal ActiveGenie components
- **Preserve internal behavior**: Let internal ActiveGenie classes interact naturally to maintain realistic test scenarios
- **Focus on boundaries**: Mock at the system boundaries (network calls, file system, databases) rather than internal class interactions

## Test Data Management
- **Don't test mocks**: Avoid writing tests that simply verify mock data returns expected values - this provides no real validation
- **Reuse existing fixtures**: Leverage existing stub files and test data to minimize maintenance overhead
- **Minimize mock data**: Fewer mocked responses make API version migrations easier and reduce brittleness

## Test Scope and Organization
- **Test class responsibilities**: Focus tests on the specific class being tested and its direct responsibilities
- **Separate concerns**: When testing scenarios involving multiple classes, create separate test files for each class
- **Use happy path for dependencies**: When testing a class that depends on others, assume dependencies work correctly (happy path)
- **One class, one test file**: Maintain a clear mapping between classes and their corresponding test files

## Test Structure
- **Arrange, Act, Assert**: Follow the AAA pattern for clear, readable tests
- **Descriptive test names**: Use clear, descriptive names that explain what is being tested
- **Single responsibility**: Each test should verify one specific behavior or scenario

## Data and Fixtures
- **Realistic test data**: Use data that closely resembles real-world scenarios
- **Minimal setup**: Keep test setup as simple as possible while still being meaningful
- **Shared fixtures**: Create reusable test fixtures for common scenarios

## Assertions
- **Test behavior, not implementation**: Focus on what the code does, not how it does it
- **Meaningful assertions**: Verify the actual business logic and expected outcomes
- **Edge cases**: Include tests for boundary conditions and error scenarios
