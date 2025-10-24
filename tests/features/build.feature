Feature: DoomLinux smoke build
  Verifies that the lightweight smoke build scaffolds expected assets.

  Scenario: Generate placeholder ISO and filesystem
    Given a clean workspace
    When I run DoomLinux in smoke mode
    Then the ISO artifact exists
    And the TrenchBroom instructions are available
    And the root filesystem directories are scaffolded
    And the GRUB configuration references DoomLinux
