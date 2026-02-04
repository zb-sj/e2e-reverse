@search @role(anonymous)
Feature: Search

  @route(/search) @smoke
  Rule: Search Input
    @desktop
    Scenario: Desktop dropdown
      When I click search input
      Then dropdown appears below

    @mobile
    Scenario: Mobile overlay
      When I tap search input
      Then full-screen overlay opens

  Rule: Search Execution
    @happy-path
    Scenario: Successful search
      When I submit search for "apartment"
      Then results list appears

    @empty-state
    Scenario: No results
      When I search "xyznonexistent"
      Then I see "검색 결과가 없습니다"

    @loading
    Scenario: Loading state
      When search is in progress
      Then loading skeleton appears

    @error
    Scenario: Service error
      When search service fails
      Then I see "일시적으로 검색할 수 없습니다"

  Rule: Search Filters
    Scenario: Apply filter
      When I click filter "가격: ₩100-500"
      Then results are filtered

    @mobile
    Scenario: Mobile filters
      When I tap "필터" button
      Then bottom sheet opens

  Rule: Autocomplete
    Scenario: Show suggestions
      When I type "아파"
      Then suggestions appear

  Rule: Search History
    @role(user)
    Scenario: Recent searches
      When I open search
      Then last 5 searches shown

    @role(anonymous)
    Scenario: No history
      Then popular searches shown

  Rule: Edge Cases
    @edge-case
    Scenario: Empty search blocked
      When input is empty
      Then search doesn't execute

    @edge-case
    Scenario: Long query
      When query exceeds 200 characters
      Then submit is disabled
