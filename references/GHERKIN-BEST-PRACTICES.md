# Gherkin Best Practices for E2E Reverse Engineering

Comprehensive guide to writing maintainable, declarative Gherkin scenarios based on industry standards (2026).

## Core Principles

### 1. Declarative over Imperative (CRITICAL)

**Rule**: Describe WHAT the system should do, not HOW to do it.

#### ❌ Bad Example (Imperative - UI-coupled)
```gherkin
Scenario: Search for property
  When user clicks on search input
  And user types "강남역" into textbox
  And user clicks the search button with class "btn-primary"
  Then the results div with id "search-results" appears
```

**Problems**:
- Breaks when UI changes (button class, div ID, element types)
- Hard to understand business behavior
- Tightly coupled to implementation
- Not maintainable

#### ✅ Good Example (Declarative - behavior-focused)
```gherkin
Scenario: Search for property by location
  When user searches for "강남역"
  Then properties in the Gangnam area are displayed
  And result count reflects available properties
```

**Benefits**:
- Survives UI refactoring
- Clear business intent
- Technology-agnostic
- Easy to understand and maintain

### 2. Background for Common Setup

Use `Background` to eliminate repeated preconditions.

#### ❌ Bad Example (Repeated setup)
```gherkin
Scenario: View property details
  Given user is logged in
  And user is on search results page
  When user selects first property
  ...

Scenario: Save property to favorites
  Given user is logged in
  And user is on search results page
  When user clicks favorite on first property
  ...
```

#### ✅ Good Example (DRY with Background)
```gherkin
Feature: Property Browsing

  Background:
    Given user is logged in
    And user has searched for properties in Gangnam

  Scenario: View property details
    When user selects first property
    Then property detail page appears
    And all property information is displayed

  Scenario: Save property to favorites
    When user marks first property as favorite
    Then property is saved to favorites list
```

### 3. Scenario Outline for Data-Driven Tests

Use `Scenario Outline` when testing same behavior with different data.

#### ❌ Bad Example (Repeated scenarios)
```gherkin
Scenario: Search Seoul location
  When user searches for "강남역"
  Then properties near Gangnam Station appear

Scenario: Search Busan location
  When user searches for "해운대"
  Then properties near Haeundae appear

Scenario: Search Incheon location
  When user searches for "송도"
  Then properties near Songdo appear
```

#### ✅ Good Example (Scenario Outline)
```gherkin
Scenario Outline: Search by location keyword
  When user searches for "<location>"
  Then properties near <area> appear
  And results are within <radius> of search point

  Examples:
    | location | area              | radius |
    | 강남역   | Gangnam Station   | 500m   |
    | 해운대   | Haeundae Beach    | 1km    |
    | 송도     | Songdo City       | 2km    |
```

### 4. One Feature per File

Organize by business feature, not by page or route.

#### ❌ Bad Organization
```
e2e/features/
├── home-page.feature          # Page-based (bad)
├── search-page.feature        # Page-based (bad)
└── detail-page.feature        # Page-based (bad)
```

#### ✅ Good Organization
```
e2e/features/
├── property-search.feature    # Feature-based (good)
├── property-browsing.feature  # Feature-based (good)
├── user-favorites.feature     # Feature-based (good)
└── chat-messaging.feature     # Feature-based (good)
```

### 5. Rules for Logical Grouping

Use `Rule` to group related scenarios within a feature.

```gherkin
@search @route(/search)
Feature: Property Search
  Users can find properties using various search criteria.

  Background:
    Given user is on search page

  Rule: Basic Search
    Scenario: Search by location name
      When user searches for "강남역"
      Then properties in Gangnam area appear

    Scenario: Search by region
      When user selects "서울시 강남구"
      Then all Gangnam district properties appear

  Rule: Advanced Filters
    Scenario: Filter by price range
      Given user has performed a search
      When user sets price filter "50만원 - 80만원"
      Then only properties in price range appear

    Scenario: Filter by room type
      Given user has performed a search
      When user selects "원룸" filter
      Then only studio apartments appear
```

### 6. Sub-Route Tags for Tab-Heavy Pages

When a page has multiple distinct tab views, use `@route()` tags at the Rule level to distinguish them:

```gherkin
@offer @route(/offer) @role(anonymous)
Feature: Property Offers
  Browse commercial and government property offers.

  @route(/offer/commercial)
  Rule: Commercial Offers Tab
    Scenario: View commercial property listings
      Given user is on offers page
      When user selects commercial tab
      Then commercial property listings appear

  @route(/offer/government)
  Rule: Government Offers Tab
    Scenario: View government property listings
      Given user is on offers page
      When user selects government tab
      Then government property listings appear

  @route(/offer/result)
  Rule: Offer Results Tab
    Scenario: View offer analysis results
      Given user is on offers page
      When user selects results tab
      Then offer analysis dashboard appears
```

This helps distinguish states when multiple tabs share one URL but present fundamentally different content.

### 7. Device-Specific Scenarios

Use `@desktop`, `@mobile`, `@tablet` tags when behavior differs.

#### ❌ Bad Example (Mixed device behaviors)
```gherkin
Scenario: User opens search
  When user clicks search input  # Desktop behavior
  Then dropdown appears
  # Or full-screen overlay on mobile?
  # Confusing!
```

#### ✅ Good Example (Device-specific scenarios)
```gherkin
@desktop
Scenario: Search autocomplete on desktop
  When user focuses search input
  Then inline dropdown appears below input
  And recent searches display first
  And popular locations display second

@mobile
Scenario: Search overlay on mobile
  When user taps search bar
  Then full-screen search overlay opens
  And search input is auto-focused
  And keyboard appears automatically
```

### 8. Meaningful Step Language

Use domain terminology, not technical jargon.

#### ❌ Bad Example (Technical language)
```gherkin
Scenario: API request succeeds
  When POST request sent to /api/search
  Then HTTP 200 response received
  And JSON payload contains data array
```

#### ✅ Good Example (Domain language)
```gherkin
Scenario: Search returns available properties
  When user searches for properties
  Then matching properties are displayed
  And property count is shown
```

### 9. State Coverage

Document all meaningful states, not just happy paths.

```gherkin
@property-detail @route(/properties/:id)
Feature: Property Detail Page

  @smoke @happy-path
  Rule: Successful Display
    Scenario: View property details
      When user opens property detail page
      Then property images are displayed
      And price information is shown
      And location map appears

  @loading
  Rule: Loading State
    Scenario: Show loading indicators
      When user navigates to property page
      Then skeleton placeholders appear
      And loading spinner shows in gallery
      Until data finishes loading

  @empty-state
  Rule: Property Not Available
    Scenario: Property removed from listing
      When user opens unavailable property
      Then "매물이 삭제되었습니다" message appears
      And alternative properties are suggested

  @error
  Rule: Network Errors
    Scenario: Property fails to load
      Given network connection is unstable
      When user opens property page
      Then error message appears
      And retry button is available
```

### 10. Given-When-Then Structure

Follow the standard structure strictly.

- **Given**: Sets up initial state/context
- **When**: Describes the action
- **Then**: Defines expected outcome
- **And/But**: Continues the previous step type

#### ❌ Bad Example (Mixed step types)
```gherkin
Scenario: Invalid structure
  When user is on homepage         # Should be Given
  Given user clicks search         # Should be When
  Then user types location         # Should be When
  And results appear               # Correct (Then continuation)
```

#### ✅ Good Example (Correct structure)
```gherkin
Scenario: Proper structure
  Given user is on homepage
  When user searches for location
  Then search results appear
  And result count is displayed
```

### 11. Avoid Technical Implementation Details

Don't reference UI elements, HTTP codes, or database operations.

#### ❌ Bad Examples
```gherkin
# Don't reference UI elements
Then the button with class "btn-submit" is enabled

# Don't reference HTTP status codes
Then HTTP 404 response is returned

# Don't reference database operations
Then the users table contains new record

# Don't reference CSS selectors
Then element with selector ".alert-danger" appears
```

#### ✅ Good Examples
```gherkin
# Focus on user-visible behavior
Then search button becomes enabled

# Focus on user experience
Then "매물을 찾을 수 없습니다" message appears

# Focus on business outcome
Then new user account is created

# Focus on visible feedback
Then error message is displayed
```

## Anti-Patterns to Avoid

### 1. Over-specified Steps
```gherkin
# ❌ Too specific
When user clicks the "검색" button at coordinates (100, 200)

# ✅ Just right
When user initiates search
```

### 2. Testing Multiple Behaviors
```gherkin
# ❌ Tests multiple things
Scenario: User can search and save and chat
  When user searches for property
  And user saves property to favorites
  And user starts chat with agent
  ...

# ✅ Separate scenarios
Scenario: Search for property
  ...

Scenario: Save property to favorites
  ...

Scenario: Chat with agent
  ...
```

### 3. Implementation-Dependent Assertions
```gherkin
# ❌ Coupled to implementation
Then Redux store contains search results
Then GraphQL cache is updated

# ✅ User-visible outcomes
Then search results are displayed
Then results update automatically
```

### 4. Vague Steps
```gherkin
# ❌ Too vague
When user does something
Then things happen

# ✅ Specific and clear
When user searches for "강남역"
Then properties near Gangnam Station appear
```

## Ralph's Generation Guidelines

When Ralph generates Gherkin scenarios, it MUST:

1. **Use declarative language** focusing on WHAT happens, not HOW
2. **Apply Background** for repeated preconditions (e.g., "Given user is logged in")
3. **Use Scenario Outline** when discovering repetitive test patterns
4. **Separate device-specific behaviors** with @desktop/@mobile tags
5. **Group related scenarios** under Rules
6. **Cover all states**: happy-path, empty-state, loading, error, edge-case
7. **Use domain terminology** from config (e.g., Korean real estate terms)
8. **Avoid implementation details** (selectors, HTTP codes, element types)
9. **One assertion per Then** (use And for additional checks)
10. **Keep scenarios focused** on single behavior/outcome

## Validation Checklist

Before committing a Gherkin scenario, verify:

- [ ] Steps describe behavior, not UI interactions
- [ ] No reference to CSS selectors, classes, IDs, or element types
- [ ] No HTTP status codes or technical errors
- [ ] Uses domain language from project context
- [ ] Background extracts common preconditions
- [ ] Scenario Outline used for data variations
- [ ] Device tags applied when behavior differs
- [ ] Given-When-Then structure followed
- [ ] Each scenario tests one behavior
- [ ] All expected states covered (happy/empty/loading/error)

## References

Based on industry best practices from:

- [Cucumber.io: Better Gherkin](https://cucumber.io/docs/bdd/better-gherkin/)
- [GitHub: Gherkin Best Practices](https://github.com/andredesousa/gherkin-best-practices)
- [TestQuality: 10 Essential Gherkin Best Practices](https://testquality.com/10-essential-gherkin-best-practices-for-effective-bdd-testing/)
- [TestQuality: Maintainable Gherkin Test Cases](https://testquality.com/best-practices-for-writing-maintainable-gherkin-test-cases/)

---

*This guide is part of the e2e-reverse skill. Use these patterns when generating scenarios during autonomous exploration.*
