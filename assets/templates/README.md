# E2E-Reverse Gherkin Templates

Reference templates demonstrating best practices for Gherkin feature files. Use these as examples when generating new features with Ralph.

## Template Files

### 1. [search.feature](search.feature)
**Entry-point feature with complex interactions**

Demonstrates:
- All scenario states (happy-path, error, empty, loading)
- Device-specific behaviors (@desktop, @mobile, @tablet)
- Role-based scenarios (@role(anonymous), @role(user))
- Background section usage
- Multiple Rules for logical grouping
- Edge cases and validation
- Performance optimization scenarios

**Use for**: Search, navigation, filters, autocomplete features

---

### 2. [user-profile.feature](user-profile.feature)
**Auth-required feature with role variations**

Demonstrates:
- Role-based access (@role(user), @role(admin), @role(anonymous))
- Sub-routes using @route() tags
- Nested route hierarchy (/profile, /profile/edit, /profile/edit/photo)
- Device-specific steps within scenarios
- Privacy and security scenarios
- Account management flows
- Form validation and error handling

**Use for**: User profiles, settings, dashboards, admin panels

---

### 3. [apartment-detail.feature](apartment-detail.feature)
**Content detail page with rich media**

Demonstrates:
- Device-responsive layouts
- Image gallery interactions
- Map and location features
- Contact forms and CTAs
- Save/share functionality
- Related content sections
- SEO and metadata considerations
- Performance optimization

**Use for**: Product details, listings, articles, content pages

---

## Key Patterns and Conventions

### Route Tags

Use `@route()` tags on Rules to indicate specific paths:

```gherkin
@route(/profile) @smoke
Rule: View Profile
  Scenario: View profile info
    ...

@route(/profile/edit)
Rule: Edit Profile
  Scenario: Update profile name
    ...

  @route(/profile/edit/photo)
  Scenario: Update profile picture
    ...
```

**Benefits**:
- Clear URL structure
- Easy to map scenarios to routes
- Supports nested route hierarchies
- Helps organize related scenarios

---

### Device-Specific Behaviors

**IMPORTANT**: Gherkin does NOT support tags between steps. Use one of these valid patterns:

#### Pattern 1: Tagged Scenarios (Recommended)
When behavior differs by device, create separate scenarios:

```gherkin
@route(/profile/edit/photo)
Rule: Update Profile Picture
  Scenario: Upload new photo
    When I upload a new photo
    Then I should see the new photo preview

  @mobile
  Scenario: Upload photo with camera
    When I upload a new photo
    And I grant camera permissions
    Then I should see the new photo preview
```

#### Pattern 2: Abstract Steps
Use a single step that's implemented differently per platform:

```gherkin
Scenario: Update profile picture
  When I upload a new photo
  And I handle permissions
  Then I should see the new photo preview
```

Where `I handle permissions`:
- Mobile: Requests camera permissions
- Desktop: Does nothing (no-op)

**When to use**:
- **Tagged Scenarios**: When flows are significantly different
- **Abstract Steps**: When only one step varies (permission, gesture, etc.)

---

### Tag Scope and Inheritance

**Feature-level tags** apply to all scenarios:
```gherkin
@user-profile @role(user)
Feature: User Profile Management
  # All scenarios require user role by default
```

**Rule-level tags** apply to scenarios within that rule:
```gherkin
@route(/profile/edit)
Rule: Edit Profile
  # All scenarios in this rule are at /profile/edit
```

**Scenario-level tags** apply only to that scenario:
```gherkin
@mobile
Scenario: Mobile-specific behavior
  # Only this scenario is mobile-specific
```

---

### State Coverage

Every feature should include scenarios for:

1. **@happy-path** - Normal successful flow
2. **@error** - Server errors, network failures, validation errors
3. **@empty-state** - No data, initial state
4. **@loading** - Loading/processing states
5. **@edge-case** - Boundary conditions, unusual inputs

---

### Role-Based Scenarios

Use `@role()` tags to indicate auth requirements:

- `@role(anonymous)` - No authentication required
- `@role(user)` - Requires logged-in user
- `@role(admin)` - Requires admin privileges
- `@role(premium)` - Requires premium subscription

**Pattern**:
```gherkin
@role(user)
Scenario: User-specific action
  Given I am logged in
  ...

@role(anonymous)
Scenario: Anonymous redirected to login
  Given I am not logged in
  When I try to access protected page
  Then I am redirected to login page
```

---

### Priority Tags

Indicate test priority for CI/CD:

- `@smoke` - Critical path, run on every commit
- `@regression` - Regular test suite, run nightly
- `@edge-case` - Boundary conditions, run weekly

---

### Background Section

Use Background for common preconditions:

```gherkin
Background:
  Given the application is loaded
  And search service is available
```

**When to use**:
- Setup shared by ALL scenarios in the feature
- Authentication state
- Service availability
- Common navigation

**When NOT to use**:
- Scenario-specific setup (put in Given step)
- State that varies between scenarios

---

### Rule Organization

Group related scenarios under Rules:

```gherkin
Rule: Search input accessibility
  # Scenarios about accessing/opening search

Rule: Search query execution
  # Scenarios about performing searches

Rule: Search filters and refinement
  # Scenarios about filtering results
```

**Benefits**:
- Logical grouping
- Easier navigation
- Clear feature structure
- Better test organization

---

### Scenario Data Tables

Use tables for structured test data:

```gherkin
Scenario: Key details section
  Then key details are displayed:
    | Field      | Example          |
    | Price      | $1,500/month     |
    | Bedrooms   | 2 BR             |
    | Bathrooms  | 1 BA             |
```

**When to use**:
- Multiple fields to verify
- Repeating similar scenarios with different data
- Clear, readable test data

---

### Step Naming Conventions

**Given** - Preconditions and setup:
```gherkin
Given user is logged in
Given user has search results displayed
Given server is experiencing issues
```

**When** - Actions and interactions:
```gherkin
When user clicks search button
When user enters text "apartment"
When user submits form
```

**Then** - Assertions and expected results:
```gherkin
Then search results appear
Then error message is displayed
Then form is submitted successfully
```

**And/But** - Additional steps of the same type:
```gherkin
When user enters name
And user enters email
And user clicks submit
```

---

## Quality Checklist

When writing new features, ensure:

- [ ] Feature has descriptive name and tag
- [ ] Background used appropriately (or omitted if not needed)
- [ ] Rules group related scenarios logically
- [ ] @route() tags on Rules when applicable
- [ ] All states covered (happy, error, empty, loading)
- [ ] Device variations documented (@desktop/@mobile/@tablet)
- [ ] Role requirements specified (@role())
- [ ] Priority tags assigned (@smoke/@regression/@edge-case)
- [ ] Steps are specific and measurable (no "it works", "success")
- [ ] Edge cases documented
- [ ] Performance expectations specified where relevant (timeouts, load times)

---

## Using Templates with Ralph

Ralph automatically references these templates when generating features:

1. **Pattern matching**: Ralph identifies feature type (search, profile, detail, etc.)
2. **Template selection**: Chooses appropriate template as reference
3. **Adaptation**: Adapts template patterns to actual app behavior
4. **Validation**: Self-validates against template quality standards

**You don't need to manually reference templates** - Ralph does this automatically during exploration.

---

## Updating Templates

When updating templates:

1. Ensure backward compatibility with existing features
2. Document new patterns in this README
3. Update all relevant template files consistently
4. Add examples for new patterns
5. Update validation rules in `scripts/validate-gherkin.md`

---

*These templates represent best practices as of 2026-02-04. Refer to [REFERENCE.md](../REFERENCE.md) for complete Gherkin conventions.*
