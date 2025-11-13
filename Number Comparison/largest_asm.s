.section .rodata
prompt:     .asciz "Enter number %d: "
fmt_in:     .asciz "%d"
msg_out:    .asciz "The largest number is: %d\n"
msg_time:   .asciz "Execution time: %ld.%09ld seconds\n" // Format for seconds and nanoseconds

    .section .bss
    .align 4
nums:       .space 12                 // 3 * 4 bytes (int)

    .align 8                          // Align for timespec structs (8-byte fields)
start_ts:   .space 16                 // struct timespec { long tv_sec; long tv_nsec; }
end_ts:     .space 16

    .text
    .global main
    .global largest
    .extern printf
    .extern scanf
    .extern clock_gettime             // External clock_gettime function

// int main(void)
main:
    // prologue
    // We need to save more registers now for time measurement,
    // and provide enough stack space.
    // x19, x20 are callee-saved, so they must be saved.
    // x29, x30 are frame pointer and link register.
    // Let's save x19-x22 to be safe with printf/scanf/clock_gettime.
    stp     x29, x30, [sp, -48]!             // Push FP and LR, reserve 48 bytes
    stp     x19, x20, [sp, 16]               // Save x19, x20
    stp     x21, x22, [sp, 32]               // Save x21, x22
    mov     x29, sp                          // Set up new frame pointer

    // --------------------------------------------------------
    // Call clock_gettime for start time
    // clock_gettime(CLOCK_MONOTONIC, &start_ts);
    // x0 = CLOCK_MONOTONIC (1)
    // x1 = address of start_ts
    // --------------------------------------------------------
    mov     x0, #1                           // CLOCK_MONOTONIC
    ldr     x1, =start_ts                    // Address of start_ts struct
    bl      clock_gettime                    // Call clock_gettime

    // i = 0
    mov     x19, #0

// for (i = 0; i < 3; i++)
.Lread_loop:
    cmp     x19, #3
    b.ge    .Lread_done

    // printf("Enter number %d: ", i+1)
    ldr     x0, =prompt            // x0 = format
    add     x1, x19, #1            // x1 = i+1
    bl      printf

    // scanf("%d", &nums[i])
    ldr     x0, =fmt_in            // x0 = "%d"
    ldr     x20, =nums             // x20 = &nums[0]
    add     x1, x20, x19, lsl #2   // x1 = &nums[i] (x19 * 4 bytes)
    bl      scanf

    add     x19, x19, #1
    b       .Lread_loop

.Lread_done:
    // call largest(nums[0], nums[1], nums[2])
    ldr     x20, =nums
    ldr     w0, [x20, #0]          // a
    ldr     w1, [x20, #4]          // b
    ldr     w2, [x20, #8]          // c
    bl      largest

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
    add     x10, x10, #1000000000            // Add 1 billion (1 second) to nsec
    sub     x11, x11, #1                     // Subtract 1 from seconds
.skip_borrow_sec:

    // Print the time
    // printf(msg_time, elapsed_sec, elapsed_nsec);
    ldr     x0, =msg_time                    // x0 = format string
    mov     x1, x11                          // x1 = elapsed_sec (first arg for %ld)
    mov     x2, x10                          // x2 = elapsed_nsec (second arg for %09ld)
    bl      printf                           // Call printf

    // return 0
    mov     w0, #0

    // epilogue
    ldp     x19, x20, [sp, 16]               // Restore x19, x20
    ldp     x21, x22, [sp, 32]               // Restore x21, x22
    ldp     x29, x30, [sp], 48               // Restore FP and LR, adjust stack
    ret


// void largest(int a, int b, int c)
// AArch64 calling convention: a,b,c in w0,w1,w2
largest:
    // prologue
    stp     x29, x30, [sp, -16]!
    mov     x29, sp

    // Determine largest in w3
    mov     w3, w0                 // largest = a

    // if (b > largest) largest = b;
    cmp     w1, w3
    ble     .Lskip_b
    mov     w3, w1
.Lskip_b:

    // if (c > largest) largest = c;
    cmp     w2, w3
    ble     .Lskip_c
    mov     w3, w2
.Lskip_c:

    // printf("The largest number is: %d\n", largest)
    ldr     x0, =msg_out           // format
    mov     w1, w3                 // value
    bl      printf

    // epilogue
    ldp     x29, x30, [sp], 16
    ret