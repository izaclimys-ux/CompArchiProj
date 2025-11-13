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
    // num1, num2, num3 (3 * 4 bytes = 12 bytes)
    // start_time (struct timeval = 16 bytes)
    // end_time (struct timeval = 16 bytes)
    // Total = 12 + 16 + 16 = 44 bytes.
    // Need to align to 16 bytes, so allocate 48 bytes.
    // We'll place variables like this:
    // [SP, #0]  : num1
    // [SP, #4]  : num2
    // [SP, #8]  : num3
    // [SP, #16] : start_time (tv_sec at #16, tv_usec at #24)
    // [SP, #32] : end_time   (tv_sec at #32, tv_usec at #40)
    SUB     SP, SP, #48

    // --- Start timing ---
    // Call gettimeofday(&start_time, NULL);
    ADD     X0, SP, #16             // Address of start_time to X0
    MOV     X1, #0                  // NULL for timezone (X1 = 0)
    BL      gettimeofday            // Call gettimeofday

    // printf("Enter three numbers: ");
    ADRP    X0, .L_prompt_string_page
    ADD     X0, X0, :lo12:.L_prompt_string
    BL      printf

    // scanf("%d %d %d", &num1, &num2, &num3);
    ADRP    X0, .L_scanf_format_string_page
    ADD     X0, X0, :lo12:.L_scanf_format_string
    ADD     X1, SP, #0              // &num1 to X1
    ADD     X2, SP, #4              // &num2 to X2
    ADD     X3, SP, #8              // &num3 to X3
    BL      scanf

    // largest(num1, num2, num3);
    LDR     W0, [SP, #0]            // num1 to W0
    LDR     W1, [SP, #4]            // num2 to W1
    LDR     W2, [SP, #8]            // num3 to W2
    BL      largest                 // Call largest function

    // --- End timing ---
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
    // Print elapsed time: printf("Execution time: %ld.%06ld seconds\n", elapsed_sec, elapsed_usec);
    ADRP    X0, .L_time_format_string_page
    ADD     X0, X0, :lo12:.L_time_format_string
    MOV     X1, X23                 // elapsed_sec to X1
    MOV     X2, X24                 // elapsed_usec to X2
    BL      printf

    // return 0;
    MOV     W0, #0                  // Set return value to 0 (for main)

    // Epilogue: Restore FP and LR, deallocate stack space
    ADD     SP, SP, #48             // Deallocate all local stack space
    LDP     X29, X30, [SP], #16
    RET

// --------------------------------------------------------------------------
// largest function (remains unchanged)
// Input: a in W0, b in W1, c in W2
// Output: Prints the largest number
// --------------------------------------------------------------------------
.align 2
.global largest
.type largest, %function
largest:
    // Prologue: Save FP and LR.
    STP     X29, X30, [SP, #-16]!
    MOV     X29, SP

    // W0 = a, W1 = b, W2 = c
    // We'll use W3 to hold 'largest_val' temporarily.

    // if (a >= b && a >= c)
    CMP     W0, W1
    BLT     .L_check_b              // If a < b, jump to check 'b'

    CMP     W0, W2
    BLT     .L_check_b              // If a < c, jump to check 'b'

    MOV     W3, W0                  // largest_val = a
    B       .L_print_result

.L_check_b:
    // else if (b >= a && b >= c)
    CMP     W1, W0
    BLT     .L_check_c              // If b < a, jump to check 'c'

    CMP     W1, W2
    BLT     .L_check_c              // If b < c, jump to check 'c'

    MOV     W3, W1                  // largest_val = b
    B       .L_print_result

.L_check_c:
    // else (largest_val = c)
    MOV     W3, W2                  // largest_val = c

.L_print_result:
    // printf("The largest number is: %d\n", largest_val);
    ADRP    X0, .L_output_string_page
    ADD     X0, X0, :lo12:.L_output_string
    MOV     W1, W3
    BL      printf

    // Epilogue: Restore FP and LR
    LDP     X29, X30, [SP], #16
    RET

// --------------------------------------------------------------------------
// Data Section
// --------------------------------------------------------------------------
.data
.align 3 // Align data to 8-byte boundary

// Strings for printf and scanf
.L_prompt_string_page:
.L_prompt_string:
    .string "Enter three numbers: "
.L_scanf_format_string_page:
.L_scanf_format_string:
    .string "%d %d %d"
.L_output_string_page:
.L_output_string:
    .string "The largest number is: %d\n"
.L_time_format_string_page:
.L_time_format_string:
    .string "Execution time: %ld.%06ld seconds\n"