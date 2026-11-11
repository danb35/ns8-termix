*** Settings ***
Library    SSHLibrary

*** Variables ***
${SCENARIO}         install
# Termix is not in the default software repositories, so the update scenario
# installs the previous release by image URL instead of by name
${PREVIOUS_IMAGE}   ghcr.io/geniusdynamics/termix:latest
${HOST}             termix.test.local
${ADMIN_USER}       admin
${ADMIN_PASSWORD}   Nethesis,1234
${module_id}        ${EMPTY}

*** Keywords ***
Login to cluster-admin
    New Page    https://${NODE_ADDR}/cluster-admin/
    Fill Text    text="Username"    ${ADMIN_USER}
    Click    button >> text="Continue"
    Fill Text    text="Password"    ${ADMIN_PASSWORD}
    Click    button >> text="Log in"
    Wait For Elements State    css=#main-content    visible    timeout=10s

Termix answers through Traefik
    ${rc} =    Execute Command    curl -f -H 'Host: ${HOST}' http://127.0.0.1/
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

Get configuration
    ${output}  ${rc} =    Execute Command    api-cli run module/${module_id}/get-configuration --data null
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    &{config} =    Evaluate    json.loads('''${output}''')    modules=json
    RETURN    &{config}

*** Test Cases ***
Check if termix is installed correctly
    IF    '${SCENARIO}' == 'update'
        ${output}  ${rc} =    Execute Command    add-module ${PREVIOUS_IMAGE} 1
        ...    return_rc=True
    ELSE
        ${output}  ${rc} =    Execute Command    add-module ${IMAGE_URL} 1
        ...    return_rc=True
    END
    Should Be Equal As Integers    ${rc}  0
    &{output} =    Evaluate    ${output}
    Set Global Variable    ${module_id}    ${output.module_id}

Check if termix can be configured
    ${rc} =    Execute Command    api-cli run module/${module_id}/configure-module --data '{"host": "${HOST}", "http2https": false, "lets_encrypt": false}'
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0
    Wait Until Keyword Succeeds    30 times    10 seconds    Termix answers through Traefik

Check if termix survives the update
    Skip If    '${SCENARIO}' != 'update'    scenario is ${SCENARIO}, nothing to update
    ${rc} =    Execute Command
    ...    api-cli run update-module --data '{"force":true,"module_url":"${IMAGE_URL}","instances":["${module_id}"]}'
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0
    &{config} =    Get configuration
    Should Be Equal    ${config.host}    ${HOST}
    Should Not Be True    ${config.http2https}
    Should Not Be True    ${config.lets_encrypt}

Check if termix works as expected
    Wait Until Keyword Succeeds    60 times    10 seconds    Termix answers through Traefik
    # Set by bin/prepare-termix-data once the data is ready for Termix 26.x
    ${rc} =    Execute Command
    ...    runagent -m ${module_id} sh -c 'podman unshare test -e "$(podman volume inspect -f "{{.Mountpoint}}" termix-data)/.ns8-termix-ready-v26"'
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

Check if OIDC settings can be saved
    # Blank OIDC URLs come from the Settings page as empty strings
    ${rc} =    Execute Command    api-cli run module/${module_id}/configure-module --data '{"host": "${HOST}", "http2https": false, "lets_encrypt": false, "oidc_client_id": "ci-client", "oidc_client_secret": "ci-not-a-secret", "oidc_issuer_url": "https://issuer.test.local", "oidc_authorization_url": "https://issuer.test.local/auth", "oidc_token_url": "https://issuer.test.local/token", "oidc_userinfo_url": ""}'
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0
    &{config} =    Get configuration
    Should Be Equal    ${config.oidc_client_id}    ci-client
    Should Be Equal    ${config.oidc_issuer_url}    https://issuer.test.local
    Should Be Equal    ${config.oidc_userinfo_url}    ${EMPTY}
    Wait Until Keyword Succeeds    30 times    10 seconds    Termix answers through Traefik

Take screenshots
    [Tags]    ui
    Import Library    Browser
    New Browser    chromium    headless=True
    New Context    ignoreHTTPSErrors=True
    Login to cluster-admin
    Go To    https://${NODE_ADDR}/cluster-admin/#/apps/${module_id}
    Wait For Elements State    iframe >>> h2 >> text="Status"    visible    timeout=10s
    Sleep    5s
    Take Screenshot    filename=${OUTPUT DIR}/browser/screenshot/1._Status.png
    Go To    https://${NODE_ADDR}/cluster-admin/#/apps/${module_id}?page=settings
    Wait For Elements State    iframe >>> h2 >> text="Settings"    visible    timeout=10s
    Sleep    5s
    Take Screenshot    filename=${OUTPUT DIR}/browser/screenshot/2._Settings.png
    Close Browser

Check if termix is removed correctly
    ${rc} =    Execute Command    remove-module --no-preserve ${module_id}
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0
