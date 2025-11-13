.text
.align 2 // Align code to 4-byte boundary

// External function declarations (required for linker)
.global printf
.global scanf
.global gettimeofday // Declare gettimeofday as external

// --------------------------------------------------------------------------
// main function
// --------------------------------------------------------------------------
.global main
.type main, %function
main:
    // Prologue: Save Frame Pointer (FP) and Link Register (LR)
    STP     X29, X30, [SP, #-16]!
    MOV     X29, SP

    // Allocate stack space for:
    // x (num)          (4 bytes)
    // start_time       (struct timeval = 16 bytes)
    // end_time         (struct timeval = 16 bytes)
    // Total = 4 + 16 + 16 = 36 bytes.
    // Need to align to 16 bytes, so allocate 48 bytes.
    // We'll place variables like this:
    // [SP, #0]  : x (num)
    // [SP, #16] : start_time (tv_sec at #16, tv_usec at #24)
    // [SP, #32] : end_time   (tv_sec at #32, tv_usec at #40)
    SUB     SP, SP, #48

    // printf("please input a number: ");
    ADRP    X0, .L_prompt_string_page
    ADD     X0, X0, :lo12:.L_prompt_string
    BL      printf

    // scanf("%d", &x);
    ADRP    X0, .L_format_string_page
    ADD     X0, X0, :lo12:.L_format_string
    ADD     X1, SP, #0              // Address of 'x' on stack (SP + 0)
    BL      scanf

    // --- Start timing for prime_check ---
    // Call gettimeofday(&start_time, NULL);
    ADD     X0, SP, #16             // Address of start_time to X0
    MOV     X1, #0                  // NULL for timezone (X1 = 0)
    BL      gettimeofday            // Call gettimeofday

    // prime_check(x);
    LDR     W0, [SP, #0]            // Load 'x' from stack into W0 (argument for prime_check)
    BL      prime_check

    // --- End timing for prime_check ---
    // Call gettimeofday(&end_time, NULL);
    ADD     X0, SP, #32             // Address of end_time to X0
    MOV     X1, #0                  // NULL for timezone (X1 = 0)
    BL      gettimeofday            // Call gettimeofday

    // Calculate elapsed time
    // X19 = start_time.tv_sec
    // X20 = start_time.tv_usec
    // X21 = end_time.tv_sec
    // X22 = end_time.tv_usec
    // X23 = elapsed_sec
    // X24 = elapsed_usec
    // Note: X19-X24 are callee-saved, so we should save them if modified.
    // In this specific case, main is essentially the top-level, so it's less critical.
    // For strict ABI compliance in nested calls, consider saving them.

    LDR     X19, [SP, #16]          // X19 = start_time.tv_sec
    LDR     X20, [SP, #24]          // X20 = start_time.tv_usec
    LDR     X21, [SP, #32]          // X21 = end_time.tv_sec
    LDR     X22, [SP, #40]          // X22 = end_time.tv_usec

    // elapsed_sec = end_time.tv_sec - start_time.tv_sec;
    SUB     X23, X21, X19           // X23 = elapsed_sec

    // elapsed_usec = end_time.tv_usec - start_time.tv_usec;
    SUB     X24, X22, X20           // X24 = elapsed_usec

    // Handle borrow if microseconds is negative
    CMP     X24, #0                 // Compare elapsed_usec with 0
    BGE     .L_skip_borrow          // If >= 0, no borrow needed

    SUB     X23, X23, #1            // Decrement elapsed_sec
    ADD     X24, X24, #1000000      // Add 1,000,000 to elapsed_usec (1 second)

.L_skip_borrow:
    // Print elapsed time: printf("Execution time for prime_check: %ld.%06ld seconds\n", elapsed_sec, elapsed_usec);
    ADRP    X0, .L_time_format_string_page
    ADD     X0, X0, :lo12:.L_time_format_string
    MOV     X1, X23                 // elapsed_sec to X1
    MOV     X2, X24                 // elapsed_usec to X2
    BL      printf

    // return 0;
    MOV     W0, #0                  // Set return value to 0

    // Epilogue: Restore FP and LR, deallocate stack space
    ADD     SP, SP, #48             // Deallocate all local stack space
    LDP     X29, X30, [SP], #16
    RET

// --------------------------------------------------------------------------
// prime_check function (remains unchanged)
// Input: x in W0
// Output: Prints whether x is prime or not
// --------------------------------------------------------------------------
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
.L_time_format_string_page:
.L_time_format_string:
    .string "Execution time for prime_check: %ld.%06ld seconds\n"