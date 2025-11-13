.text
.align 2 // Align code to 4-byte boundary

// --------------------------------------------------------------------------
// main function
// --------------------------------------------------------------------------
.global main
.type main, %function
main:
    // Prologue: Save Frame Pointer (FP) and Link Register (LR)
    // SP is adjusted by -16 to make space for FP and LR
    STP     X29, X30, [SP, #-16]!   // Push FP and LR onto stack, pre-index SP
    MOV     X29, SP                 // Set FP to current SP

    // Allocate stack space for local variables num1, num2, num3 (3 * 4 bytes = 12 bytes)
    // We need to keep stack 16-byte aligned. So allocate 16 bytes.
    // [SP, #0] for num1, [SP, #4] for num2, [SP, #8] for num3
    SUB     SP, SP, #16

    // printf("Enter three numbers: ");
    // Load the address of the prompt string into X0
    ADRP    X0, .L_prompt_string_page // Get page address
    ADD     X0, X0, :lo12:.L_prompt_string // Add low 12 bits offset
    BL      printf                  // Call printf

    // scanf("%d %d %d", &num1, &num2, &num3);
    // Load the address of the format string into X0
    ADRP    X0, .L_scanf_format_string_page // Get page address
    ADD     X0, X0, :lo12:.L_scanf_format_string // Add low 12 bits offset

    // Pass addresses of num1, num2, num3 for scanf arguments
    // &num1 will be at SP + 0
    // &num2 will be at SP + 4
    // &num3 will be at SP + 8
    ADD     X1, SP, #0              // &num1 to X1
    ADD     X2, SP, #4              // &num2 to X2
    ADD     X3, SP, #8              // &num3 to X3
    BL      scanf                   // Call scanf

    // largest(num1, num2, num3);
    // Load values of num1, num2, num3 from stack into W0, W1, W2 (arguments for largest)
    LDR     W0, [SP, #0]            // num1 to W0
    LDR     W1, [SP, #4]            // num2 to W1
    LDR     W2, [SP, #8]            // num3 to W2
    BL      largest                 // Call largest function

    // return 0;
    MOV     W0, #0                  // Set return value to 0 (for main)

    // Epilogue: Restore FP and LR, deallocate stack space
    ADD     SP, SP, #16             // Deallocate space for num1, num2, num3
    LDP     X29, X30, [SP], #16     // Pop FP and LR from stack, post-index SP
    RET                             // Return from main

// --------------------------------------------------------------------------
// largest function
// Input: a in W0, b in W1, c in W2
// Output: Prints the largest number
// --------------------------------------------------------------------------
.align 2
.global largest
.type largest, %function
largest:
    // Prologue: Save FP and LR. No local variables needing stack space,
    // but good practice for function calls.
    STP     X29, X30, [SP, #-16]!   // Push FP and LR
    MOV     X29, SP                 // Set FP

    // W0 = a, W1 = b, W2 = c
    // We'll use W3 to hold 'largest_val' temporarily.

    // if (a >= b && a >= c)
    CMP     W0, W1                  // Compare a with b
    BLT     .L_check_b              // If a < b, jump to check 'b' (a is not the largest)

    CMP     W0, W2                  // If a >= b, then compare a with c
    BLT     .L_check_b              // If a < c, jump to check 'b' (a is not the largest)

    MOV     W3, W0                  // If a >= b AND a >= c, then largest_val = a
    B       .L_print_result         // Go to print result

.L_check_b:
    // else if (b >= a && b >= c)
    CMP     W1, W0                  // Compare b with a
    BLT     .L_check_c              // If b < a, jump to check 'c' (b is not the largest)

    CMP     W1, W2                  // If b >= a, then compare b with c
    BLT     .L_check_c              // If b < c, jump to check 'c' (b is not the largest)

    MOV     W3, W1                  // If b >= a AND b >= c, then largest_val = b
    B       .L_print_result         // Go to print result

.L_check_c:
    // else (largest_val = c)
    MOV     W3, W2                  // largest_val = c

.L_print_result:
    // printf("The largest number is: %d\n", largest_val);
    // Load the address of the output string into X0
    ADRP    X0, .L_output_string_page // Get page address
    ADD     X0, X0, :lo12:.L_output_string // Add low 12 bits offset

    // Move largest_val (from W3) into W1 for printf's second argument
    MOV     W1, W3
    BL      printf                  // Call printf

    // Epilogue: Restore FP and LR
    LDP     X29, X30, [SP], #16     // Pop FP and LR from stack
    RET                             // Return from largest

// --------------------------------------------------------------------------
// Data Section
// --------------------------------------------------------------------------
.data
.align 3 // Align data to 8-byte boundary

// Strings for printf and scanf
.L_prompt_string_page: // Page anchor for linker
.L_prompt_string:
    .string "Enter three numbers: "
.L_scanf_format_string_page: // Page anchor for linker
.L_scanf_format_string:
    .string "%d %d %d"
.L_output_string_page: // Page anchor for linker
.L_output_string:
    .string "The largest number is: %d\n"