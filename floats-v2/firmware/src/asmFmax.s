/*** asmFmax.s   ***/
#include <xc.h>
.syntax unified

@ Declare the following to be in data memory
.data  
.align

@ Define the globals so that the C code can access them

/* create a string */
.global nameStr
.type nameStr,%gnu_unique_object
    
/*** STUDENTS: Change the next line to your name!  **/
nameStr: .asciz "Desiree Werner"  
 
.align

/* initialize a global variable that C can access to print the nameStr */
.global nameStrPtr
.type nameStrPtr,%gnu_unique_object
nameStrPtr: .word nameStr   /* Assign the mem loc of nameStr to nameStrPtr */

.global f0,f1,fMax,signBitMax,storedExpMax,realExpMax,mantMax
.type f0,%gnu_unique_object
.type f1,%gnu_unique_object
.type fMax,%gnu_unique_object
.type sbMax,%gnu_unique_object
.type storedExpMax,%gnu_unique_object
.type realExpMax,%gnu_unique_object
.type mantMax,%gnu_unique_object

.global sb0,sb1,storedExp0,storedExp1,realExp0,realExp1,mant0,mant1
.type sb0,%gnu_unique_object
.type sb1,%gnu_unique_object
.type storedExp0,%gnu_unique_object
.type storedExp1,%gnu_unique_object
.type realExp0,%gnu_unique_object
.type realExp1,%gnu_unique_object
.type mant0,%gnu_unique_object
.type mant1,%gnu_unique_object
 
.align
@ use these locations to store f0 values
f0: .word 0
sb0: .word 0
storedExp0: .word 0  /* the unmodified 8b exp value extracted from the float */
realExp0: .word 0
mant0: .word 0
 
@ use these locations to store f1 values
f1: .word 0
sb1: .word 0
realExp1: .word 0
storedExp1: .word 0  /* the unmodified 8b exp value extracted from the float */
mant1: .word 0
 
@ use these locations to store fMax values
fMax: .word 0
sbMax: .word 0
storedExpMax: .word 0
realExpMax: .word 0
mantMax: .word 0

.global nanValue 
.type nanValue,%gnu_unique_object
nanValue: .word 0x7FFFFFFF            

@ Tell the assembler that what follows is in instruction memory    
.text
.align

/********************************************************************
 function name: initVariables
    input:  none
    output: initializes all f0*, f1*, and *Max varibales to 0
********************************************************************/
.global initVariables
 .type initVariables,%function
initVariables:
    /* YOUR initVariables CODE BELOW THIS LINE! Don't forget to push and pop! */
PUSH {r4, r5, lr}

    MOV r5, 0                 @ r5 = 0

    LDR r4, =f0               @ Initialize all variables in order
    STR r5, [r4]              @ f0
    STR r5, [r4, #4]          @ sb0
    STR r5, [r4, #8]          @ storedExp0
    STR r5, [r4, #12]         @ realExp0
    STR r5, [r4, #16]         @ mant0

    LDR r4, =f1
    STR r5, [r4]
    STR r5, [r4, #4]
    STR r5, [r4, #8]
    STR r5, [r4, #12]
    STR r5, [r4, #16]

    LDR r4, =fMax
    STR r5, [r4]
    STR r5, [r4, #4]
    STR r5, [r4, #8]
    STR r5, [r4, #12]
    STR r5, [r4, #16]

    POP {r4, r5, pc}

    /* YOUR initVariables CODE ABOVE THIS LINE! Don't forget to push and pop! */

    
/********************************************************************
 function name: getSignBit
    input:  r0: address of mem containing 32b float to be unpacked
            r1: address of mem to store sign bit (bit 31).
                Store a 1 if the sign bit is negative,
                Store a 0 if the sign bit is positive
                use sb0, sb1, or signBitMax for storage, as needed
    output: [r1]: mem location given by r1 contains the sign bit
********************************************************************/
.global getSignBit
.type getSignBit,%function
getSignBit:
    /* YOUR getSignBit CODE BELOW THIS LINE! Don't forget to push and pop! */
 PUSH {r2, lr}
    LDR r2, [r0]              @ Load float
    LSR r2, r2, #31           @ Shift bit 31 to bit 0
    STR r2, [r1]              @ Store to destination
    POP {r2, pc}
    /* YOUR getSignBit CODE ABOVE THIS LINE! Don't forget to push and pop! */
    

    
/********************************************************************
 function name: getExponent
    input:  r0: address of mem containing 32b float to be unpacked
      
    output: r0: contains the unpacked original STORED exponent bits,
                shifted into the lower 8b of the register. Range 0-255.
            r1: always contains the REAL exponent, equal to r0 - 127.
                It is a signed 32b value. This function doesn't
                check for +/-Inf or +/-0, so r1 always contains
                r0 - 127.
                
********************************************************************/
.global getExponent
.type getExponent,%function
getExponent:
    /* YOUR getExponent CODE BELOW THIS LINE! Don't forget to push and pop! */
     PUSH {r2, r3, lr}
    LDR r2, [r0]                      @ Load float
    LDR r3, =0x7F800000
    AND r0, r2, r3                    @ Mask exponent
    LSR r0, r0, #23                   @ Shift into position

    LDR r3, =127
    SUB r1, r0, r3                    @ real = stored - 127
    POP {r2, r3, pc}
    /* YOUR getExponent CODE ABOVE THIS LINE! Don't forget to push and pop! */
   

    
/********************************************************************
 function name: getMantissa
    input:  r0: address of mem containing 32b float to be unpacked
      
    output: r0: contains the mantissa WITHOUT the implied 1 bit added
                to bit 23. The upper bits must all be set to 0.
            r1: contains the mantissa WITH the implied 1 bit added
                to bit 23. Upper bits are set to 0. 
********************************************************************/
.global getMantissa
.type getMantissa,%function
getMantissa:
    /* YOUR getMantissa CODE BELOW THIS LINE! Don't forget to push and pop! */
    PUSH {r2, r3, lr}
    LDR r2, [r0]                     @ Load float
    LDR r3, =0x007FFFFF
    AND r0, r2, r3                   @ Extract raw mantissa

    MOV r1, r0
    LDR r3, =0x00800000             @ Bit 23 mask
    ORR r1, r1, r3                  @ Add implied 1
    POP {r2, r3, pc}
    /* YOUR getMantissa CODE ABOVE THIS LINE! Don't forget to push and pop! */
   


    
/********************************************************************
 function name: asmIsZero
    input:  r0: address of mem containing 32b float to be checked
                for +/- 0
      
    output: r0:  0 if floating point value is NOT +/- 0
                 1 if floating point value is +0
                -1 if floating point value is -0
      
********************************************************************/
.global asmIsZero
.type asmIsZero,%function
asmIsZero:
    /* YOUR asmIsZero CODE BELOW THIS LINE! Don't forget to push and pop! */
BX LR    
     PUSH {r1, lr}
    LDR r1, [r0]
    LDR r0, =0
    CMP r1, r0
    BEQ plus_zero

    LDR r0, =0x80000000
    CMP r1, r0
    BEQ minus_zero

    MOV r0, 0
    B end_zero

plus_zero:
    MOV r0, 1
    B end_zero

minus_zero:
    MOV r0, -1

end_zero:
    POP {r1, pc}
    /* YOUR asmIsZero CODE ABOVE THIS LINE! Don't forget to push and pop! */
   


    
/********************************************************************
 function name: asmIsInf
    input:  r0: address of mem containing 32b float to be checked
                for +/- infinity
      
    output: r0:  0 if floating point value is NOT +/- infinity
                 1 if floating point value is +infinity
                -1 if floating point value is -infinity
      
********************************************************************/
.global asmIsInf
.type asmIsInf,%function
asmIsInf:
    /* YOUR asmIsInf CODE BELOW THIS LINE! Don't forget to push and pop! */
BX LR    
     PUSH {r1, lr}
    LDR r1, [r0]
    LDR r0, =0x7F800000
    CMP r1, r0
    BEQ plus_inf

    LDR r0, =0xFF800000
    CMP r1, r0
    BEQ minus_inf

    MOV r0, 0
    B end_inf

plus_inf:
    MOV r0, 1
    B end_inf

minus_inf:
    MOV r0, -1

end_inf:
    POP {r1, pc}

    /* YOUR asmIsInf CODE ABOVE THIS LINE! Don't forget to push and pop! */
   


    
/********************************************************************
function name: asmFmax
function description:
     max = asmFmax ( f0 , f1 )
     
where:
     f0, f1 are 32b floating point values passed in by the C caller
     max is the ADDRESS of fMax, where the greater of (f0,f1) must be stored
     
     if f0 equals f1, return either one
     notes:
        "greater than" means the most positive number.
        For example, -1 is greater than -200
     
     The function must also unpack the greater number and update the 
     following global variables prior to returning to the caller:
     
     signBitMax: 0 if the larger number is positive, otherwise 1
     realExpMax: The REAL exponent of the max value, adjusted for
                 (i.e. the STORED exponent - (127 o 126), see lab instructions)
                 The value must be a signed 32b number
     mantMax:    The lower 23b unpacked from the larger number.
                 If not +/-INF and not +/- 0, the mantissa MUST ALSO include
                 the implied "1" in bit 23! (So the student's code
                 must make sure to set that bit).
                 All bits above bit 23 must always be set to 0.     

********************************************************************/    
.global asmFmax
.type asmFmax,%function
asmFmax:   

    /* YOUR asmFmax CODE BELOW THIS LINE! VVVVVVVVVVVVVVVVVVVVV  */
    
BX LR    
     PUSH {r4-r7, lr}

    @ Load both values
    LDR r4, =f0
    LDR r5, [r4]
    LDR r6, =f1
    LDR r7, [r6]

    CMP r5, r7
    BGT use_f0
    BLT use_f1

use_f0:   @ f0 is greater or equal
    LDR r0, =f0
    LDR r1, =fMax
    LDR r2, [r0]
    STR r2, [r1]
    BL unpack_f0
    B done

use_f1:   @ f1 is greater
    LDR r0, =f1
    LDR r1, =fMax
    LDR r2, [r0]
    STR r2, [r1]
    BL unpack_f1

done:
    POP {r4-r7, pc}

/************************************************************
 Helper: unpack_f0 ? Unpack f0 into *_Max fields
*************************************************************/
unpack_f0:
    PUSH {lr}
    LDR r0, =f0
    LDR r1, =sbMax
    BL getSignBit

    LDR r0, =f0
    BL getExponent
    LDR r2, =storedExpMax
    STR r0, [r2]
    LDR r2, =realExpMax
    STR r1, [r2]

    LDR r0, =f0
    BL getMantissa
    LDR r2, =mantMax
    STR r1, [r2]
    POP {pc}

/************************************************************
 Helper: unpack_f1 ? Unpack f1 into *_Max fields
*************************************************************/
unpack_f1:
    PUSH {lr}
    LDR r0, =f1
    LDR r1, =sbMax
    BL getSignBit

    LDR r0, =f1
    BL getExponent
    LDR r2, =storedExpMax
    STR r0, [r2]
    LDR r2, =realExpMax
    STR r1, [r2]

    LDR r0, =f1
    BL getMantissa
    LDR r2, =mantMax
    STR r1, [r2]
    POP {pc}

    /* YOUR asmFmax CODE ABOVE THIS LINE! ^^^^^^^^^^^^^^^^^^^^^  */

   

/**********************************************************************/   
.end  /* The assembler will not process anything after this directive!!! */
           



