@apartment-detail @role(anonymous)
Feature: Apartment Detail

  @route(/apartments/:id) @smoke
  Rule: Page Load
    Scenario: Load details
      When I navigate to apartment page
      Then title and price are shown

    @desktop
    Scenario: Desktop layout
      Then image gallery on left 60%
      And details panel on right 40%

    @mobile
    Scenario: Mobile layout
      Then full-width hero image at top
      And details stack vertically

    @loading
    Scenario: Loading skeleton
      When page is loading
      Then skeleton placeholders appear

    @error
    Scenario: Not found
      When apartment doesn't exist
      Then 404 page appears

  Rule: Image Gallery
    @desktop
    Scenario: Desktop lightbox
      When I click image
      Then lightbox opens full-screen

    @mobile
    Scenario: Mobile swipe
      When I swipe left
      Then next image slides in

    @empty-state
    Scenario: No images
      Then placeholder shown

  Rule: Information
    Scenario: Key details
      Then price, rooms, area displayed

    Scenario: Description expand
      When description is long
      Then "더보기" link appears
      When I click "더보기"
      Then full text expands

  Rule: Map
    Scenario: Show map
      Then embedded map displayed

    @mobile
    Scenario: Full-screen map
      When I tap "큰 지도 보기"
      Then full-screen map opens

  Rule: Contact
    @role(anonymous)
    Scenario: Contact form
      When I click "문의하기"
      Then form appears

    @role(user)
    Scenario: Pre-filled form
      When I click "문의하기"
      Then email pre-filled

    @mobile
    Scenario: Quick actions
      When I tap floating button
      Then action sheet shows options

  Rule: Save and Share
    @role(user)
    Scenario: Save to favorites
      When I click heart icon
      Then saved to favorites

    @role(anonymous)
    Scenario: Login prompt
      When I click heart icon
      Then login prompt appears

    @mobile
    Scenario: Native share
      When I tap share
      Then native share sheet opens

  Rule: Related Listings
    Scenario: Similar apartments
      Then "비슷한 매물" section shows 4-6 listings

    @empty-state
    Scenario: No similar
      Then "비슷한 매물이 없습니다" shown
