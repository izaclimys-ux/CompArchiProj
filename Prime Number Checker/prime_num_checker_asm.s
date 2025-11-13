.section .rodata                         // Read-only data (strings)
prompt:         .asciz "Please input a number: "
fmt_in:         .asciz "%d"                  // Format string for scanf
msg_prime:      .asciz "%d is a prime number\n"
msg_not_prime:  .asciz "%d is not a prime number\n"
msg_time:       .asciz "Execution time: %ld.%09ld seconds\n" // For seconds and nanoseconds

    .section .bss                            // Uninitialized data
    .align 4
num:            .space 4                     // Reserve 4 bytes for the integer input

    .align 8                                 // Align for timespec struct
start_ts:       .space 16                    // struct timespec { long tv_sec; long tv_nsec; }
end_ts:         .space 16

    .text
    .global main                             // Export main to linker
    .extern printf                           // External C library functions
    .extern scanf
    .extern clock_gettime                    // External clock_gettime function


// ------------------------------------------------------------
// main function
// ------------------------------------------------------------
main:
    // Standard function prologue (stack setup)
    stp     x29, x30, [sp, -48]!             // Push frame pointer (x29) and link register (x30)
    mov     x29, sp                          // Set up new frame pointer
    // Save registers used by printf/scanf/clock_gettime,
    // and our own w19, w20.
    // x19, x20 are callee-saved, so we MUST save them if we modify them.
    // x0-x18, x30 are caller-saved.
    // We'll save x19-x22, x29, x30 to be safe
    // stp     x19, x20, [sp, -16]!            // Moved to larger prologue
    // stp     x21, x22, [sp, -16]!            // Need to save if used

    // Since we're using more stack space for `stp` now,
    // let's adjust the stack frame size. x29, x30 is 16 bytes.
    // We need to save enough general purpose registers.
    // x19-x22 are callee-saved, so we should save them.
    // x0-x18 are caller-saved, so if any function we call modifies them,
    // we assume it's okay unless we need their values AFTER the call.
    // Here, we mainly care about w20 (num) and w19 (loop counter).
    // Let's save x19-x22.
    stp     x19, x20, [sp, 16]               // Save x19, x20
    stp     x21, x22, [sp, 32]               // Save x21, x22

    // --------------------------------------------------------
    // Call clock_gettime for start time
    // clock_gettime(CLOCK_MONOTONIC, &start_ts);
    // x0 = CLOCK_MONOTONIC (1)
    // x1 = address of start_ts
    // --------------------------------------------------------
    mov     x0, #1                           // CLOCK_MONOTONIC
    ldr     x1, =start_ts                    // Address of start_ts struct
    bl      clock_gettime                    // Call clock_gettime

    // --------------------------------------------------------
    // printf("Please input a number: ");
    // --------------------------------------------------------
    ldr     x0, =prompt                      // x0 = address of prompt string (first arg)
    bl      printf                           // Call printf

    // --------------------------------------------------------
    // scanf("%d", &num);
    // --------------------------------------------------------
    ldr     x0, =fmt_in                      // x0 = address of "%d"
    ldr     x1, =num                         // x1 = address of variable num
    bl      scanf                            // Call scanf("%d", &num)

    // --------------------------------------------------------
    // Load input number into w20 (for computation)
    // --------------------------------------------------------
    ldr     w20, num                         // w20 = num

    // --------------------------------------------------------
    // if (n < 2) → not prime
    // --------------------------------------------------------
    cmp     w20, #2                          // Compare n with 2
    b.ge    .check_loop                      // If n >= 2, go to check_loop
    b       .print_not_prime_and_time        // Else, print "not prime" and then time

    // --------------------------------------------------------
    // Prime checking loop setup
    // --------------------------------------------------------
.check_loop:
    mov     w19, #2                          // w19 = i = 2 (loop counter)

    // while (i * i <= n)
.loop_cond:
    mul     w1, w19, w19                     // w1 = i * i
    cmp     w1, w20                          // Compare i*i with n
    b.gt    .print_prime_and_time            // If i*i > n, number is prime

    // --------------------------------------------------------
    // Compute remainder = n % i
    // remainder = n - (n / i) * i
    // --------------------------------------------------------
    udiv    w2, w20, w19                     // w2 = quotient = n / i
    msub    w3, w2, w19, w20                 // w3 = n - (q * i) = remainder

    cbz     w3, .print_not_prime_and_time    // If remainder == 0 → not prime

    add     w19, w19, #1                     // i++
    b       .loop_cond                       // Repeat the loop

    // --------------------------------------------------------
    // If no divisors found → prime
    // --------------------------------------------------------
.print_prime_and_time:
    ldr     x0, =msg_prime                   // x0 = address of "%d is a prime number\n"
    mov     w1, w20                          // w1 = n (printf second argument)
    bl      printf                           // Call printf(msg_prime, n)
    b       .measure_and_print_time          // Jump to time measurement

    // --------------------------------------------------------
    // Print "not prime" if any divisor found
    // --------------------------------------------------------
.print_not_prime_and_time:
    ldr     x0, =msg_not_prime               // x0 = address of "%d is not a prime number\n"
    mov     w1, w20                          // w1 = n
    bl      printf                           // Call printf(msg_not_prime, n)

    // --------------------------------------------------------
    // Time Measurement and Printing
    // --------------------------------------------------------
.measure_and_print_time:
    // Call clock_gettime for end time
    // clock_gettime(CLOCK_MONOTONIC, &end_ts);
    mov     x0, #1                           // CLOCK_MONOTONIC
    ldr     x1, =end_ts                      // Address of end_ts struct
    bl      clock_gettime                    // Call clock_gettime

    // Calculate elapsed time (end_ts - start_ts)
    // start_ts and end_ts are structs: { long tv_sec; long tv_nsec; }
    // tv_sec is at offset 0, tv_nsec is at offset 8
    ldr     x4, =start_ts                    // x4 = address of start_ts
    ldr     x5, =end_ts                      // x5 = address of end_ts

    // Load start seconds and nanoseconds
    ldr     x6, [x4, #0]                     // x6 = start_ts.tv_sec
    ldr     x7, [x4, #8]                     // x7 = start_ts.tv_nsec

    // Load end seconds and nanoseconds
    ldr     x8, [x5, #0]                     // x8 = end_ts.tv_sec
    ldr     x9, [x5, #8]                     // x9 = end_ts.tv_nsec

    // Calculate elapsed nanoseconds: x10 = x9 - x7 (end_nsec - start_nsec)
    sub     x10, x9, x7

    // Calculate elapsed seconds: x11 = x8 - x6 (end_sec - start_sec)
    sub     x11, x8, x6

    // Handle borrow from nanoseconds if end_nsec < start_nsec
    cmp     x10, #0                          // Is elapsed nanoseconds negative?
    b.ge    .skip_borrow_sec                 // If not, no borrow needed
    sub     x10, x10, #-1000000000           // Add 1 billion (1 second) to nsec
    sub     x11, x11, #1                     // Subtract 1 from seconds
.skip_borrow_sec:

    // Print the time
    // printf(msg_time, elapsed_sec, elapsed_nsec);
    ldr     x0, =msg_time                    // x0 = format string
    mov     x1, x11                          // x1 = elapsed_sec (first arg for %ld)
    mov     x2, x10                          // x2 = elapsed_nsec (second arg for %09ld)
    bl      printf                           // Call printf

    // --------------------------------------------------------
    // Exit function (restore stack and return)
    // --------------------------------------------------------
.exit:
    ldp     x19, x20, [sp, 16]               // Restore x19, x20
    ldp     x21, x22, [sp, 32]               // Restore x21, x22
    ldp     x29, x30, [sp], 48               // Restore frame pointer and return address, adjust stack
    mov     w0, #0                           // Return 0 from main
    ret                                      // Return to OS