.text
.align 2
.global main
.type main, %function

main:
    STP     X29, X30, [SP, #-16]!
    MOV     X29, SP

    // Allocate space for local variable 'x' on the stack
    // We'll store 'x' at [SP, #0]
    SUB     SP, SP, #16             // Ensure stack is 16-byte aligned

    // printf("please input a number: ");
    ADRP    X0, .L_prompt_string_page
    ADD     X0, X0, :lo12:.L_prompt_string
    BL      printf

    // scanf("%d", &x);
    ADRP    X0, .L_format_string_page
    ADD     X0, X0, :lo12:.L_format_string
    ADD     X1, SP, #0              // Address of 'x' on stack (SP + 0)
    BL      scanf

    // prime_check(x);
    LDR     W0, [SP, #0]            // Load 'x' from stack into W0 (argument for prime_check)
    BL      prime_check

    // return 0;
    MOV     W0, #0                  // Set return value to 0

    // Function epilogue
    ADD     SP, SP, #16             // Deallocate stack space for 'x'
    LDP     X29, X30, [SP], #16
    RET

.align 2
.global prime_check
.type prime_check, %function

prime_check:
    // Function entry prologue
    // Save FP and LR, and callee-saved registers X19, X20
    STP     X29, X30, [SP, #-16]!
    STP     X19, X20, [SP, #-16]!   // Save W19, W20 (used for xyz, i)
    MOV     X29, SP

    // X0 contains the input 'x'
    // W19 will be used for 'xyz'
    // W20 will be used for 'i' in the loop

    MOV     W19, #0                 // xyz = 0

    // Condition: if (x <= 1 || (x > 2 && x % 2 == 0))

    // Check x <= 1
    CMP     W0, #1
    BLE     .L_not_prime_print   // If x <= 1, branch to print not prime

    // Check (x > 2 && x % 2 == 0)
    CMP     W0, #2
    BLE     .L_check_x_eq_2         // If x <= 2, go to x==2 check

    // Calculate x % 2
    AND     W1, W0, #1              // W1 = x % 2
    CMP     W1, #0
    BNE     .L_check_x_eq_2         // If x % 2 != 0, it's not an even number, proceed to x==2 check

    // If we reach here, x > 2 AND x % 2 == 0, so it's not prime
    B       .L_not_prime_print

.L_check_x_eq_2:
    // Condition: else if (x == 2)
    CMP     W0, #2
    BNE     .L_start_loop           // If x != 2, branch to start loop

    // If x == 2, print prime
    ADRP    X0, .L_prime_string_page
    ADD     X0, X0, :lo12:.L_prime_string
    MOV     W1, W0                  // Move 'x' to W1 for printf's second argument
    BL      printf
    B       .L_function_exit        // Exit function

.L_start_loop:
    // else block: for (int i = 3; i * i <= x; i += 2)
    MOV     W20, #3                 // i = 3

.L_loop_condition:
    // i * i <= x
    // Use a 64-bit register for the product to avoid overflow if x is large
    UMULL   X1, W20, W20            // X1 = i * i (unsigned multiply)
    UXTW    X2, W0                  // Extend W0 (x) to 64-bit for comparison
    CMP     X1, X2                  // Compare (long long)i*i with (long long)x
    BGT     .L_end_loop             // If i*i > x, loop ends

    // if (x % i == 0)
    UDIV    W1, W0, W20             // W1 = x / i (unsigned division)
    MUL     W1, W1, W20             // W1 = (x / i) * i
    CMP     W1, W0                  // Compare (x/i)*i with x
    BNE     .L_loop_increment       // If not equal, not divisible, continue loop

    // if (x % i == 0), then it's not prime
    MOV     W19, #1                 // xyz = 1
    B       .L_end_loop             // Break out of loop

.L_loop_increment:
    ADD     W20, W20, #2            // i += 2
    B       .L_loop_condition       // Go back to loop condition

.L_end_loop:
    // After loop, check xyz
    CMP     W19, #0
    BEQ     .L_prime_print          // If xyz == 0, print prime

.L_not_prime_print:               // Common branch for printing "not prime"
    ADRP    X0, .L_not_prime_string_page
    ADD     X0, X0, :lo12:.L_not_prime_string
    MOV     W1, W0                  // Move 'x' to W1 for printf's second argument
    BL      printf
    B       .L_function_exit

.L_prime_print:
    ADRP    X0, .L_prime_string_page
    ADD     X0, X0, :lo12:.L_prime_string
    MOV     W1, W0                  // Move 'x' to W1 for printf's second argument
    BL      printf

.L_function_exit:
    // Function epilogue
    MOV     SP, X29                 // Restore SP from FP
    LDP     X19, X20, [SP], #16     // Restore W19, W20
    LDP     X29, X30, [SP], #16     // Restore FP and LR
    RET

.data
.align 3
.L_prompt_string_page:
.L_prompt_string:
    .string "please input a number: "
.L_format_string_page:
.L_format_string:
    .string "%d"
.L_prime_string_page:
.L_prime_string:
    .string "%d is a prime number\n"
.L_not_prime_string_page:
.L_not_prime_string:
    .string "%d is a not prime number\n"