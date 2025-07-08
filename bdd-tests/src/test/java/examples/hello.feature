# File: bdd-tests/src/test/java/examples/hello.feature
Feature: Hello World

  Scenario: say hello
    Given url 'https://postman-echo.com/get'
    When method get
    Then status 200