# --------------------------------------------------------------------
# dc.s
#
# Desk Calculator (dc) (x86-64)
#
# Student ID:
# --------------------------------------------------------------------

    .equ   BUFFERSIZE, 32
    .equ   EOF, -1

# --------------------------------------------------------------------

.section ".rodata"

#strings for format, error handling

scanfFormat:
     .asciz "%s"

printfFormat:
     .asciz "%d\n"

errorbyOverflow:
     .asciz "dc: overflow happens\n"

errorbyEmptystack:
     .asciz "dc: stack empty\n"

errorbyZerodivision:
     .asciz "dc: divide by zero\n"

errorbyZeroremainder:
     .asciz "dc: remainder by zero\n"

# --------------------------------------------------------------------

    .section ".data"

# --------------------------------------------------------------------

    .section ".bss"

# --------------------------------------------------------------------
    .section ".text"

    # -------------------------------------------------------------
    # int powerfunc(int base, int exponent)
    # Runs the power function.  Returns result.
    # -------------------------------------------------------------

    .globl	powerfunc
    .type   powerfunc, @function

    # base is stored in %rdi
    # exponent is stored in %rsi

powerfunc:

    pushq %rbp
    movq %rsp, %rbp
    movl $1, %eax          # initialize result to 1

    movl %esi, %ecx        # move exponent to ecx

    cmp $0, %ecx           # check if exponent is 0
    je .power_done         # if exponent is 0, skip the loop

    .power_loop:
         imul %edi, %eax        # multiply result by base
         loop .power_loop       # loop until ecx becomes 0

    .power_done:
         movq %rbp, %rsp
         popq %rbp

    ret            # return result

# -------------------------------------------------------------
# int main(void)
# Runs desk calculator program.  Returns 0.
# -------------------------------------------------------------

    .text
    .globl  main
    .type   main, @function

main:

    pushq   %rbp
    movq    %rsp, %rbp

    # char buffer[BUFFERSIZE]
    subq    $BUFFERSIZE, %rsp

    # Note %rsp must be 16-B aligned before call


.input:

    leaq scanfFormat, %rdi   # format string for scanf
    leaq -BUFFERSIZE(%rbp), %rsi   # load address of buffer 
    xor %eax, %eax           # set %al to 0
    call scanf               # read user input

    cmp $EOF, %eax           # check if user input == EOF
    je .quit

    #checking boundary conditions

    movzbq -BUFFERSIZE(%rbp), %rdi  # checking is it digit
    call isdigit
    test %rax,%rax    

    je .inputOperation

    leaq -BUFFERSIZE(%rbp),%rdi
    call atoi

    pushq %rax  #push integer
    subq $8, %rsp

    jmp .input
    




.inputOperation:

    movb -BUFFERSIZE(%rbp), %al    # get the first character of the input

    cmp $'p', %al            # check 'p' is the character 
    je .print          

    cmp $'q', %al            # check 'q' is the character 
    je .quit

    cmp $'+', %al            # check '+' is the character 
    je .addition            

    cmp $'-', %al            # check '-' is the character 
    je .subtraction          

    cmp $'^', %al            # check '^' is the character 
    je .pow

    cmp $'*', %al            # check '*' is the character 
    je .multiplication      

    cmp $'/', %al            # check '/' is the character 
    je .division

    cmp $'%', %al            # check '%' is the character 
    je .mod

    cmp $'c', %al            # check 'clear' is the character 
    je .clear

    cmp $'f', %al            # check 'f' is the character 
    je .flush 

    cmp $'_', %al            # check '_' is the character 
    je .negative 
                  

    jmp .input              

# negate the number
.negative:
    
    leaq    -BUFFERSIZE+1(%rbp), %rdi
    call    atoi

    negq    %rax    # negation

    # Store the negated value back on the stack
    pushq  %rax
    subq   $8, %rsp

    jmp .input
 

.addition:
    
    leaq    -BUFFERSIZE(%rbp), %r13
    cmpq    %r13, %rsp
    jge     .emptystackerror1

    addq    $8, %rsp # load from stack
    popq    %rbx

    # stack empty error
    cmpq    %rsp, %r13
    jle     .emptystackerror2

    addq    $8, %rsp
    popq    %rax
    
    
    addl    %ebx, %eax  #add 
    jo     .overflowerror   # error by overflow
    
    pushq   %rax
    subq   $8, %rsp
    jmp     .input
    

.subtraction:
    
    leaq    -BUFFERSIZE(%rbp), %r13
    cmpq    %r13, %rsp
    jge     .emptystackerror1

    addq    $8, %rsp
    popq    %rbx

    # stack empty error
    cmpq    %rsp, %r13
    jle     .emptystackerror2


    addq    $8, %rsp
    popq    %rax
    
    subl    %ebx, %eax
    jo     .overflowerror # error by overflow

    pushq   %rax
    subq   $8, %rsp
    jmp     .input


.multiplication:
   
    leaq    -BUFFERSIZE(%rbp), %r13
    cmpq    %r13, %rsp
    jge     .emptystackerror1

    addq    $8, %rsp
    popq    %rbx

    # stack empty error
    cmpq    %rsp, %r13
    jle     .emptystackerror2

    addq    $8, %rsp
    popq    %rax


    imull   %ebx, %eax
    jo     .overflowerror # error by overflow


    pushq   %rax
    subq   $8, %rsp
    jmp     .input

.division:

    leaq    -BUFFERSIZE(%rbp), %r13
    cmpq    %r13, %rsp
    jge     .emptystackerror1


    addq    $8, %rsp
    popq    %rbx

    # stack empty error
    cmpq    %rsp, %r13
    jle     .emptystackerror2

    addq    $8, %rsp
    popq    %rax

    # error when devide by 0
    cmpq    $0, %rbx
    je      .divisonzeroerror

    cqto
    idivq   %rbx # divide

    movq    $2147483647, %r14
    cmpq    %rax, %r14
    jl    .overflowerror # error by overflow

    pushq   %rax
    subq   $8, %rsp
    jmp     .input

.mod:

    leaq    -BUFFERSIZE(%rbp), %r13
    cmpq    %r13, %rsp
    jge     .emptystackerror1

    addq    $8, %rsp
    popq    %rbx

    # stack empty error
    cmpq    %rsp, %r13
    jle     .emptystackerror2

    addq    $8, %rsp
    popq    %rax

    # error when devide by 0
    cmpq    $0, %rbx
    je      .reminderzeroerror

    cqto
    idivq   %rbx  # devide
    jo     .overflowerror # error by overflow

    pushq   %rdx
    subq   $8, %rsp
    jmp     .input

.pow:

    leaq    -BUFFERSIZE(%rbp), %r13
    cmpq    %r13, %rsp
    jge     .emptystackerror1

    addq    $8, %rsp
    popq    %rbx
    
    movq    %rbx, %rsi

    # stack empty error
    cmpq    %rsp, %r13
    jle     .emptystackerror2

    addq    $8, %rsp
    popq    %rdi

    # call powerfunction
    call    powerfunc

    cmpq    $0, %rax
    jl      .overflowerror   # error by overflow

    pushq   %rax
    subq   $8, %rsp
    jmp     .input

# print everything in stack 
.flush:

    movq    %rsp, %rbx
    leaq   -BUFFERSIZE(%rbp), %r13
  
    .recursionloop:
       
        cmpq    %rbx, %r13
        jle     .input

        addq   $8, %rbx
        movq   (%rbx), %rsi

        subq   $8, %rbx
        leaq    printfFormat, %rdi
        call    printf
        addq    $8, %rbx

        
        addq    $8, %rbx
        jmp     .recursionloop # add 8 again before jump to loop


# clear the whole stack
.clear:

    movq %rsp, %rbx     # Save the current stack pointer in %rbx
    addq $BUFFERSIZE, %rbx   # Calculate the new stack pointer by adding BUFFERSIZE
    movq %rbx, %rsp     # Move the new stack pointer to %rsp
    jmp .input          # Jump to the input section to continue the program
    

# error when empty stack, case1 and case2

.emptystackerror1:

    movq    stderr, %rdi
    leaq    errorbyEmptystack, %rsi

    call    fprintf
    jmp     .input


.emptystackerror2:

    pushq   %rbx
    subq    $8, %rsp

    movq    stderr, %rdi
    leaq    errorbyEmptystack, %rsi
    
    call    fprintf
    jmp     .input


.divisonzeroerror:

    movq    stderr, %rdi
    leaq    errorbyZerodivision, %rsi
    call    fprintf

    # return 1
    movq    $1, %rax
    addq    $BUFFERSIZE, %rsp
    movq    %rbp, %rsp
    popq    %rbp
    ret

.reminderzeroerror:

    movq    stderr, %rdi
    leaq    errorbyZeroremainder, %rsi
    call    fprintf
    
    # return 1
    movq    $1, %rax
    addq    $BUFFERSIZE, %rsp
    movq    %rbp, %rsp
    popq    %rbp
    ret

.overflowerror:

    movq    stderr, %rdi
    leaq   errorbyOverflow, %rsi
    call    fprintf
    
    # return 1
    movq    $1, %rax
    addq    $BUFFERSIZE, %rsp
    movq    %rbp, %rsp
    popq    %rbp
    ret

.quit:	

    movq    $0, %rax
    addq    $BUFFERSIZE, %rsp
    movq    %rbp, %rsp
    popq    %rbp
    ret


# print stack's top
.print:
    
    # error when empty stack
    leaq    -BUFFERSIZE(%rbp), %r13
    cmpq    %r13, %rsp
    jge     .emptystackerror1


    addq    $8, %rsp #load stack's top
    popq    %rax
    leaq    printfFormat, %rdi

    movq    %rax, %rsi  #load stack's top
    pushq   %rax
    subq   $8, %rsp

    call    printf
    jmp     .input