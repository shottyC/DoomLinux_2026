Feature: Developer tooling consistency
  Ensures recommended developer tooling is present and documented.

  Scenario: Supporting scripts and configs exist
    Then the install script exists and is executable
    And the devcontainer configuration is available
    And the VSCode launch configuration is available
    And the README references miso usage
    And the smoke summary log is emoji rich
