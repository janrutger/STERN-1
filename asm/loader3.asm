

. $VIDEO_MEM 1
% $VIDEO_MEM 14336

. $VIDEO_SIZE 1
# 2k - 1 = 2047
% $VIDEO_SIZE 2047

. $INT_VECTORS 1
% $INT_VECTORS 3072

. $mem_start 1
% $mem_start 0

# Prog_start adres = 4608
. $prog_start 1
% $prog_start 4096

. $random_seed 1
% $random_seed 12345 

# define a buffer for incomming keystrokes
. $KBD_BUFFER 16
. $KBD_BUFFER_ADRES 1
. $KBD_READ_PNTR 1
. $KBD_WRITE_PNTR 1

# define RTC based params
. $CURRENT_TIME 1

# Define a pointer for the scheduler routine to be called by RTC
. $scheduler_routine_ptr 1
% $scheduler_routine_ptr @dummy_scheduler_task

. $DU0_baseadres 1 
% $DU0_baseadres 12303

. $SIO_baseadres 1
% $SIO_baseadres 12295

. $NIC_baseadres 1
% $NIC_baseadres 12283

INCLUDE printing
INCLUDE serialIO
include networkR3
INCLUDE random
INCLUDE errors

@init_stern

    ldi Z 0

    # init keyboard buffer
    sto Z $KBD_READ_PNTR
    sto Z $KBD_WRITE_PNTR
    ldi M $KBD_BUFFER
    sto M $KBD_BUFFER_ADRES

    # Initialize the scheduler pointer to the dummy scheduler
    ;ldi M @dummy_scheduler_task
    ;sto M $scheduler_routine_ptr

    # init networkcard (NIC) 
    call @init_nic_buffer

    # set the ISR vectors
    ldi I 0
    ldi M @KBD_WRITE
    stx M $INT_VECTORS

    ldi I 1
    ldi M @clear_screen
    stx M $INT_VECTORS

    ldi I 2
    ldi M @fill_screen
    stx M $INT_VECTORS

    ldi I 3
    ldi M @DRAW_CHAR
    stx M $INT_VECTORS

    ldi I 4
    ldi M @scroll_line
    stx M $INT_VECTORS

    ldi I 5
    ldi M @DRAW_SPRITE
    stx M $INT_VECTORS

    ldi I 6
    ldi M @OPEN_FILE
    stx M $INT_VECTORS

    ldi I 7
    ldi M @READ_FILE_LINE
    stx M $INT_VECTORS

    # RTC interrupt
    ldi I 8  
    ldi M @RTC_ISR
    stx M $INT_VECTORS

    # NIC receive interrupt
    ldi I 9
    ldi M @read_nic_isr
    stx M $INT_VECTORS 

    # NIC send Interrupt
    ; equ ~networkSend 10
    ; ldi I ~networkSend
    ; ldi M @write_nic_isr
    ; stx M $INT_VECTORS



    ## Done interrupt vectors

    # don't forget to enable Interrupts
    # int 1, clears the screen, 
    # return from interrupt (rti)  enbles interrupts

    int 1

ret



# Interrupts ISR
## keyboard ISR handler
## Register A containts the keyboard value
@KBD_WRITE 
    # check for full buffer
    ldm M $KBD_WRITE_PNTR
    addi M 1
    andi M 15
    ldm L $KBD_READ_PNTR
    tste M L 

    # when true, the buffer is full, do nothing
    jmpt :end_kbd_write

    # otherwise store value in buffer
    inc I $KBD_WRITE_PNTR
    stx A $KBD_BUFFER_ADRES

    # check for last adres in buffer
    # check modulo 16, by andi 15
    ldm M $KBD_WRITE_PNTR
    andi M 15
    # cycle to 0 when mod = 0
    tste M Z
    jmpf :end_kbd_write
        sto Z $KBD_WRITE_PNTR
:end_kbd_write    
rti


@KBD_READ 
    # It's a subroutine
    # returns kbd value in A 
    # returns \null when empty
    di
    # check for empty buffer
    ldm I $KBD_READ_PNTR
    ldm M $KBD_WRITE_PNTR
    tste I M 
    jmpt :empty_kbd_buffer
        # when not empty, read buffer to a
        ldx A $KBD_BUFFER_ADRES

    addi I 1
    sto I $KBD_READ_PNTR

    # check for last adres in buffer
    # check modulo
    ldm M $KBD_READ_PNTR
    andi M 15
    # cycle to 0 when mod = 0
    tste M Z
    jmpf :end_kbd_read
        sto Z $KBD_READ_PNTR 
        jmp :end_kbd_read  
    

    :empty_kbd_buffer
        ldi A \null

:end_kbd_read 
ei   
ret
## END keyboard ISR



@fill_screen
. $video_pointer 1
sto Z $video_pointer
ldi M 1
ldm L $VIDEO_SIZE
    :loop
        inc I $video_pointer
        stx M $VIDEO_MEM
        tste I L
    jmpf :loop
rti


@clear_screen
; $video_pointer 1
sto Z $video_pointer
ldi M \space
ldm L $VIDEO_SIZE
    :loop_clear
        inc I $video_pointer
        stx M $VIDEO_MEM
        tste I L
    jmpf :loop_clear
rti


@DRAW_CHAR 
    # Reg X = X-pos on screen
    # Reg Y = Y-pos on screen
    # Reg C =  char to draw

    # TODO: This ISR is currently non-functional as $FONTS is no longer pre-loaded.
    # The system needs a new mechanism for character rendering.
    # For now, this ISR does nothing to prevent errors.
    # Example:
    # ldi A \E  ; Load 'E' for Error
    # call @PRINT_CHAR_SERIAL ; (if such a routine exists for debugging)
    # or simply return:
rti




@scroll_line
### MOVE memory block n positions
. $screen_start 1
. $read_pointer 1
. $pxls_to_shift 1
. $shifting 1

ldm M $VIDEO_MEM
sto M $screen_start

# n postions to move
# 1 lines x 64 pixels = 64
addi M 64

# pointer to read adres
sto M $read_pointer

# number of shifts
# total lenght of block - 1 = 63
# pixels to shift
ldm M $VIDEO_SIZE
subi M 63
sto M $pxls_to_shift

ldi I 0
sto I $shifting

:shift_loop
    inc I $shifting
    ldx M $read_pointer
    stx M $screen_start

    ldm K $shifting
    ldm L $pxls_to_shift
    tste K L 
jmpf :shift_loop

# fill with \space
ldi K \space
ld M Z
:fill_zero
    inc I $shifting
    stx K $screen_start

    addi M 1
    # 1 line x 64 pixels = 64
    # tst M 384
    tst M 64
jmpf :fill_zero    

rti



# print a sprite
# Reg A = sprite widht (X)
# Reg B = sprite height (Y)
# Reg C = pointer to sprite array
# Reg X = X pos of the first pixel
# Reg Y = Y pos of the first pixel

@DRAW_SPRITE
   call @draw_sprite_function   
rti

## File based ISR's

@OPEN_FILE
    # expects the filename hash in A 
    # Returns statusregister is Idle (0)

    # store A in data_register
    # dataregister index = 2 
    ldi I 2
    stx A $DU0_baseadres

    # set the commmand (0) open file
    ldi M 0
    # commandregister index = 1
    ldi I 1
    stx M $DU0_baseadres 

    # sets status (2) request from host
    ldi M 2
    # statusregister index = 0
    ldi I 0
    stx M $DU0_baseadres

    :wait_for_ack_open_file
        # read status register
        ldi I 0
        ldx M $DU0_baseadres
        # check for ack (1) request from disk
        tst M 1
        jmpf :wait_for_ack_open_file

    # set status to Idle after file open
    ldi M 0
    ldi I 0
    stx M $DU0_baseadres

rti

. $disk_read_buffer 64
. $disk_read_buffer_indx 1
. $disk_read_buffer_pntr 1
% $disk_read_buffer_pntr $disk_read_buffer


@READ_FILE_LINE
    # returns a line from the file in $disk_read_buffer
    # Returns \null at end of file 
    # Returns statusregister is Idle (0)

    sto Z $disk_read_buffer_indx

    :read_line
        # set command_register read
        ldi I 1
        ldi M 1
        stx M $DU0_baseadres
        # set status_register request from host
        ldi I 0
        ldi M 2
        stx M $DU0_baseadres

        :wait_for_ack_read_line
            # read status register
            ldi I 0
            ldx M $DU0_baseadres
            # check for ack (1) request from disk
            tst M 1 
        jmpf :wait_for_ack_read_line
            # read data_register
            ldi I 2
            ldx M $DU0_baseadres

            # store in disk_read_buffer
            inc I $disk_read_buffer_indx
            stx M $disk_read_buffer_pntr
            
            # check for \Return (end of line)
            tst M \Return
            jmpt :end_file_read

            # check for \null (end of file)
            tst M \null
            jmpt :end_file_read

        jmp :read_line  
    
:end_file_read
    # set status to Idle after line read
    ldi M 0
    ldi I 0
    stx M $DU0_baseadres
rti


# RTC isr
@RTC_ISR
    sto A $CURRENT_TIME  

    ldm I $scheduler_routine_ptr
    callx $mem_start

rti


## End of the ISR's






## Helper routines

# calc pixel pointer
# expects X and Y register for pos pixel
# calculates the mem pointer pos for this X Y
@calc_pxl_pntr
    ld I Y 
    muli I 64
    add I X
ret


@toggle_pxl
    # Expects Reg I as pxl mem pointer
    # Toggle pixel Ri mem position

    # draw the pixel
    ldi C 1
    xorx C $VIDEO_MEM
    stx C $VIDEO_MEM
ret

@write_pxl
    # Expects Reg I as pxl mem pointer
    # Write pixel Ri mem position

    # draw the pixel
    xorx C $VIDEO_MEM
    stx C $VIDEO_MEM
ret


@check_XY_bounderies
# checkd of the X an Y positions
# Fits on screen, 
# reset XY when out of bounderie
. $last_x_pos 1
. $last_y_pos 1

% $last_x_pos 64
% $last_y_pos 32

# check bounderies
    ldm M $last_x_pos
    dmod X M 
    ld X M
    ldm M $last_y_pos
    dmod Y M
    ld Y M
ret


# draw sprite helper functio
@draw_sprite_function
    . $start_x 1
    . $start_y 1
    sto X $start_x
    sto Y $start_y

    . $pixel_w_pntr 1
    . $pixel_h_pntr 1
    . $current_sprite 1
    . $sprite_pntr 1

    sto C $current_sprite

    sto Z $sprite_pntr
    sto Z $pixel_h_pntr

    :row_loop_sprite
        inc K $pixel_h_pntr
        sto Z $pixel_w_pntr
        ldm X $start_x
        
        :col_loop
            inc L $pixel_w_pntr

            inc I $sprite_pntr
            ldx C $current_sprite

            add X L
            add Y K
            call @check_XY_bounderies
            call @calc_pxl_pntr
            call @write_pxl

            ldm X $start_x
            ldm Y $start_y

        ldm M $pixel_w_pntr
        tstg A M
        jmpt :col_loop

    ldm M $pixel_h_pntr
    tstg B M
    jmpt :row_loop_sprite 
ret

@dummy_scheduler_task
    # This is a placeholder. The kernel will replace the pointer
    # to $scheduler_routine_ptr with its own scheduler.
ret
