
@kernel_init
    call @init_stern 
    call @init_keywords 

    # init Network Message Dispatcher
    ldi M @network_message_dispatcher
    sto M $scheduler_routine_ptr

@kernel
    call @prompt_system
    call @get_input_line
    call @tokennice_input_buffer
    call @parse_tokens
    jmp @kernel
halt




## INCLUDE helpers


INCLUDE read_char
INCLUDE get_input_line

INCLUDE tokennice_input_buffer
INCLUDE check_char_type
INCLUDE get_number_token
INCLUDE get_operator_token
INCLUDE get_string_token

INCLUDE parse_tokens
INCLUDE keyword_handling

INCLUDE math
INCLUDE keyword_defs
INCLUDE keyword_calls
INCLUDE keyword_init

INCLUDE var_handling
INCLUDE stacks

INCLUDE printing

INCLUDE networkdispatcher


