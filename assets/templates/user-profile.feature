@user-profile @role(user)
Feature: User Profile Management

  @route(/profile) @smoke
  Rule: View Profile
    Scenario: View profile info
      Given I am logged in
      When I navigate to my profile
      Then I should see my profile information

    @role(anonymous)
    Scenario: Anonymous redirected
      When I try to access /profile
      Then I am redirected to login

  @route(/profile/edit)
  Rule: Edit Profile
    Scenario: Update profile name
      Given I am on the profile edit page
      When I change my name to "새이름"
      Then I should see "저장되었습니다" message

    @error
    Scenario: Validation error
      When I enter invalid email
      Then I should see "올바른 이메일을 입력하세요"

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

  @route(/profile/settings)
  Rule: Account Settings
    Scenario: Change password
      When I enter new password
      Then I should see "비밀번호가 변경되었습니다"

    @edge-case
    Scenario: Weak password rejected
      When I enter password "123"
      Then submit button is disabled

  @route(/profile/activity)
  Rule: Activity History
    @empty-state
    Scenario: No activity yet
      Then I should see "활동 내역이 없습니다"

  @role(admin)
  Rule: Admin Actions
    Scenario: Admin views profile
      When I view another user's profile
      Then I see "사용자 정지" option
