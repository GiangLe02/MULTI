#################################################################################
#    File : reset.s
#    Author : Alain Greiner
#################################################################################
#       This is an improved boot code for a bi-processor architecture.
#    Depending on the proc_id, each processor
#       - initializes the interrupt vector.
#       - initializes the ICU MASK registers.
#       - initializes the TIMER .
#       - initializes the Status Register.
#       - initializes the stack pointer.
#       - initializes the EPC register, and jumps to the user code.
#################################################################################
        
    .section .reset,"ax",@progbits

    .extern seg_stack_base
    .extern seg_data_base

    .func   reset
    .type   reset, %function

reset:
    .set noreorder

    # get the processor id
    mfc0  $27,    $15,    1      # get the proc_id
    andi  $27,    $27,    0x1    # no more than 2 processors
    bne   $27,    $0,     proc1
    nop

proc0:
    # initialises interrupt vector entries for PROC[0]
    la  $10,    _interrupt_vector
    la  $11,    _isr_timer
    sw  $11,    8($10)          # write to the 3rd place in the _interrupt_vector (in tp5_top.cpp, first place is for DMA, second is for IOC, third is for TIMER)
    # initializes the ICU[0] MASK register
    la  $10,    0x9f000000      # address of ICU
    li  $11,    0x00000004      # 4 in HEX == 100 in binary, which activates 3rd interruption
    sw  $11,    8($10)          # write to ICU_SET for ICU[0]
    # initializes TIMER[0] PERIOD and RUNNING registers
    la  $10,    0x91000000      # address of TIMER
    li  $11,    0x0000c350      # 50000 in HEX
    sw  $11,    8($10)          # write to TIMER_PERIOD for TIMER[0]
    li  $11,    0x00000003      # 3 == 11 in binary, i.e. both bits of TIMER_MODE
    sw  $11,    4($10)          # write to TIMER_MODE for TIMER[0]
    # initializes stack pointer for PROC[0]
    la    $29,    seg_stack_base
    li    $27,    0x10000        # stack size = 64K
    addu  $29,    $29,    $27    # $29 <= seg_stack_base + 64K

    # initializes SR register for PROC[0]
    li    $26,    0x0000FF13    
    mtc0  $26,    $12            # SR <= 0x0000FF13

    # jump to main in user mode: main[0]
    la    $26,    seg_data_base
    lw    $26,    0($26)         # $26 <= main[0]
    mtc0  $26,    $14            # write it in EPC register
    eret

proc1:
    # initialises interrupt vector entries for PROC[1]
    la  $10,    _interrupt_vector
    la  $11,    _isr_timer
    sw  $11,    16($10)         # 5th place
    # initializes the ICU[1] MASK register
    la  $10,    0x9f000000
    li  $11,    0x00000010      # 10000 in binary
    sw  $11,    40($10)
    # initializes TIMER[1] PERIOD and RUNNING registers
    la  $10,    0x91000000
    li  $11,    0x000186a0      # 100000 in HEX
    sw  $11,    24($10)
    li  $11,    0x00000003
    sw  $11,    20($10)
    # initializes stack pointer for PROC[1]
    la    $29,    seg_stack_base
    li    $27,    0x20000        # stack size = 128K
    addu  $29,    $29,    $27    # $29 <= seg_stack_base + 64K

    # initializes SR register for PROC[1]
    li    $26,    0x0000FF13    
    mtc0  $26,    $12            # SR <= 0x0000FF13

    # jump to main in user mode: main[1]
    la    $26,    seg_data_base
    lw    $26,    4($26)         # $26 <= main[0]
    mtc0  $26,    $14            # write it in EPC register
    eret

    .set reorder

    .set reorder

    .endfunc
    .size    reset, .-reset

