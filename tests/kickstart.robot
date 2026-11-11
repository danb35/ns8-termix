*** Settings ***
Library    SSHLibrary

*** Variables ***
${HOST}    termix.test.local

*** Test Cases ***
Check if termix is installed correctly
    ${output}  ${rc} =    Execute Command    add-module ${IMAGE_URL} 1
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    &{output} =    Evaluate    ${output}
    Set Suite Variable    ${module_id}    ${output.module_id}

Check if termix can be configured
    ${rc} =    Execute Command    api-cli run module/${module_id}/configure-module --data '{"host": "${HOST}", "http2https": false, "lets_encrypt": false}'
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

Check if termix works as expected
    Wait Until Keyword Succeeds    30 times    10 seconds    Termix answers through Traefik

Check if termix is removed correctly
    ${rc} =    Execute Command    remove-module --no-preserve ${module_id}
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

*** Keywords ***
Termix answers through Traefik
    ${rc} =    Execute Command    curl -f -H 'Host: ${HOST}' http://127.0.0.1/
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0
