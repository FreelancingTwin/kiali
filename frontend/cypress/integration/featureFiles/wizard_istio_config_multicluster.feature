@wizard-istio-config-multi-cluster
@multi-cluster
# don't change first line of this file - the tag is used for the test scripts to identify the test suite

Feature: Kiali Istio Config page

  On the Istio Config page for multicluster, an admin should be able to create Istio objects in both clusters
  if a certain namespace and Istio CRDs are located in a remote cluster.

  Background:
    Given user is at administrator perspective
    And user is at the "istio" page

  Scenario: Try to Create a Gateway without selecting any cluster
    When user deletes gateway named "bookinfo-gateway-mc" and the resource is no longer available in any cluster
    And user selects the "bookinfo" namespace
    And user clicks in the "Gateway" Istio config actions
    And user sees the "Create Gateway" config wizard
    And user types "bookinfo-gateway-mc" in the "name" input
    And user adds a server to a server list
    Then the preview button should be disabled
    And user types "website.com" in the "hosts_0" input
    And user types "8080" in the "addPortNumber_0" input
    And user types "foobar" in the "addPortName_0" input
    Then the preview button should be disabled

  Scenario: Try to Create a Gateway in both clusters without Istio CRDs present in the remote cluster 
    When user deletes gateway named "bookinfo-gateway-mc" and the resource is no longer available in any cluster
    And user selects the "bookinfo" namespace
    And user clicks in the "Gateway" Istio config actions
    And user sees the "Create Gateway" config wizard
    And user selects "east,west" from the cluster dropdown
    And user types "bookinfo-gateway-mc" in the "name" input
    And user adds a server to a server list
    Then the preview button should be disabled
    And user types "website.com" in the "hosts_0" input
    And user types "8080" in the "addPortNumber_0" input
    And user types "foobar" in the "addPortName_0" input
    And user previews the configuration
    And user creates the istio config
    Then an error message "Could not create Istio Gateway objects" is displayed
    And the "Gateway" "bookinfo-gateway-mc" should be listed in "east" "bookinfo" namespace 
    And the "Gateway" "bookinfo-gateway-mc" should not be listed in "west" "bookinfo" namespace 

  @skip
  @remote-istio-crds
  # We can test for both the CRDs being and not being present in the remote cluster, but some order of execution
  # using the Gherkin tags is necessary. We don't want the suite to install/remove the CRDs and restart the 
  # Kiali pod multiple times during a single run.
  Scenario: Try to Create a Gateway in both clusters with Istio CRDs present in the remote cluster 
    When user deletes gateway named "bookinfo-gateway-mc" and the resource is no longer available in any cluster
    And Istio CRDs are "" present in the "west" cluster
    And user selects the "bookinfo" namespace
    And user clicks in the "Gateway" Istio config actions
    And user sees the "Create Gateway" config wizard
    And user selects "east,west" from the cluster dropdown
    And user types "bookinfo-gateway-mc" in the "name" input
    And user adds a server to a server list
    Then the preview button should be disabled
    And user types "website.com" in the "hosts0" input
    And user types "8080" in the "addPortNumber0" input
    And user types "foobar" in the "addPortName0" input
    And user previews the configuration
    And user creates the istio config
    And the "Gateway" "bookinfo-gateway-mc" should be listed in "east" "bookinfo" namespace 
    And the "Gateway" "bookinfo-gateway-mc" should be listed in "west" "bookinfo" namespace

  @skip
  @sleep-app
  # For this test, I deployed a sleep app in the east cluster. 
  Scenario: Try to create a remotely located Gateway in a namespace, which is only present in the local cluster
    When user selects the "sleep" namespace
    And user clicks in the "Gateway" Istio config actions
    And user sees the "Create Gateway" config wizard
    Then an info message "Namespace: sleep is not found in cluster west" is displayed
    And user selects "west" from the cluster dropdown
    And user types "sleep-gateway" in the "name" input
    And user adds a server to a server list
    Then the preview button should be disabled
    And user types "website.com" in the "hosts0" input
    And user types "8080" in the "addPortNumber0" input
    And user types "foobar" in the "addPortName0" input
    And user previews the configuration
    And user creates the istio config
    Then the "Gateway" "sleep-gateway" should not be listed in "sleep" namespace
