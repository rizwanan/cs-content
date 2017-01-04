#   (c) Copyright 2016 Hewlett-Packard Enterprise Development Company, L.P.
#   All rights reserved. This program and the accompanying materials
#   are made available under the terms of the Apache License v2.0 which accompany this distribution.
#
#   The Apache License is available at
#   http://www.apache.org/licenses/LICENSE-2.0
#
########################################################################################################################
#!!
#! @description: Authenticates and retrieves a list of all Helion Development Platform / Stackato users.
#!
#! @input host: Helion Development Platform / Stackato host
#! @input username: Helion Development Platform / Stackato username
#! @input password: Helion Development Platform / Stackato password
#! @input proxy_host: Optional - proxy server used to access Helion Development Platform / Stackato services
#! @input proxy_port: Optional - proxy server port used to access Helion Development Platform / Stackato services
#!                    Default: '8080'
#! @input proxy_username: Optional - User name used when connecting to proxy
#! @input proxy_password: Optional - Proxy server password associated with <proxy_username> input value
#!
#! @output return_result: Response of the operation in case of success, error message otherwise
#! @output return_code: '0' if success, '-1' otherwise
#! @output status_code: Code returned by the operation
#! @output error_message: Return_result if status_code is not '200'
#! @output users_list: List of all spaces on Helion Development Platform / Stackato instance
#! @output usernames_list: List containing only the usernames of the users_list
#!
#! @result SUCCESS: List with existing users on Helion Development Platform / Stackato host was successfully retrieved
#! @result GET_AUTHENTICATION_FAILURE: Authentication call failed
#! @result GET_AUTHENTICATION_TOKEN_FAILURE: Authentication token could not be obtained from authentication call response
#! @result GET_USERS_FAILURE: Get users call failed
#! @result GET_USERS_LIST_FAILURE: List with existing users on Helion Development Platform / Stackato could not be
#!                                 retrieved
#! @result GET_USERNAMES_LIST_FAILURE: list with existing usernames on Helion Development Platform / Stackato could not
#!                                     be retrieved
#!!#
########################################################################################################################

namespace: io.cloudslang.stackato.users

imports:
  stackato: io.cloudslang.stackato
  utils: io.cloudslang.stackato.utils
  rest: io.cloudslang.base.http
  json: io.cloudslang.base.json

flow:
  name: get_users

  inputs:
    - host
    - username
    - password:
        sensitive: true
    - proxy_host:
        required: false
    - proxy_port:
        default: '8080'
        required: false
    - proxy_username:
        required: false
    - proxy_password:
        required: false
        sensitive: true

  workflow:
    - authentication:
        do:
          stackato.get_authentication:
            - host
            - username
            - password
            - proxy_host
            - proxy_port
            - proxy_username
            - proxy_password
        publish:
          - return_result
          - error_message
          - token
        navigate:
          - SUCCESS: get_users_call
          - GET_AUTHENTICATION_FAILURE: GET_AUTHENTICATION_FAILURE
          - GET_AUTHENTICATION_TOKEN_FAILURE: GET_AUTHENTICATION_TOKEN_FAILURE

    - get_users_call:
        do:
          rest.http_client_get:
            - url: ${'https://' + host + '/v2/users'}
            - username
            - password
            - proxy_host
            - proxy_port
            - proxy_username
            - proxy_password
            - headers: "${'Authorization: bearer ' + token}"
            - content_type: 'application/json'
        publish:
          - return_result
          - error_message
          - return_code
          - status_code
        navigate:
          - SUCCESS: get_users_list
          - FAILURE: GET_USERS_FAILURE

    - get_users_list:
        do:
          json.get_value:
            - json_input: ${return_result}
            - json_path: "resources"
        publish:
          - users_list: ${return_result}
        navigate:
          - SUCCESS: get_usernames_list
          - FAILURE: GET_USERS_LIST_FAILURE

    - get_usernames_list:
        do:
          utils.get_usernames_list:
            - json_input: ${return_result}
        publish:
          - usernames_list
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: GET_USERNAMES_LIST_FAILURE

  outputs:
    - return_result
    - return_code
    - status_code
    - error_message: ${return_result if return_code == '-1' or status_code != '200' else ''}
    - users_list
    - usernames_list

  results:
    - SUCCESS
    - GET_AUTHENTICATION_FAILURE
    - GET_AUTHENTICATION_TOKEN_FAILURE
    - GET_USERS_FAILURE
    - GET_USERS_LIST_FAILURE
    - GET_USERNAMES_LIST_FAILURE
