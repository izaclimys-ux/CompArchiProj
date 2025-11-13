.section .rodata                         // Read-only data (strings)
prompt:         .asciz "Please input a number: "
fmt_in:         .asciz "%d"                  // Format string for scanf
msg_prime:      .asciz "%d is a prime number\n"
msg_not_prime:  .asciz "%d is not a prime number\n"

.section .bss                            // Uninitialized data
.align 4
num:            .space 4                     // Reserve 4 bytes for the integer input

.text
.global main                             // Export main to linker
.extern printf                           // External C library functions
.extern scanf
// ------------------------------------------------------------
// main function
// ------------------------------------------------------------
main:
// Standard function prologue (stack setup)
stp     x29, x30, [sp, -16]!             // Push frame pointer (x29) and link register (x30)
mov     x29, sp                          // Set up new frame pointer
stp     x19, x20, [sp, -16]!             // Save registers x19 and x20 (we will use them)

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
b       .print_not_prime                 // Else, print "not prime"

// --------------------------------------------------------
// Prime checking loop setup
// --------------------------------------------------------
.check_loop:
mov     w19, #2                          // w19 = i = 2 (loop counter)

// while (i * i <= n)
.loop_cond:
mul     w1, w19, w19                     // w1 = i * i
cmp     w1, w20                          // Compare ii with n
b.gt    .print_prime                     // If ii > n, number is prime

// --------------------------------------------------------
// Compute remainder = n % i
// remainder = n - (n / i) * i
// --------------------------------------------------------
udiv    w2, w20, w19                     // w2 = quotient = n / i
msub    w3, w2, w19, w20                 // w3 = n - (q * i) = remainder

cbz     w3, .print_not_prime             // If remainder == 0 → not prime

add     w19, w19, #1                     // i++
b       .loop_cond                       // Repeat the loop

// --------------------------------------------------------
// If no divisors found → prime
// --------------------------------------------------------
.print_prime:
ldr     x0, =msg_prime                   // x0 = address of "%d is a prime number\n"
mov     w1, w20                          // w1 = n (printf second argument)
bl      printf                           // Call printf(msg_prime, n)
b       .exit                            // Jump to program exit

// --------------------------------------------------------
// Print "not prime" if any divisor found
// --------------------------------------------------------
.print_not_prime:
ldr     x0, =msg_not_prime               // x0 = address of "%d is not a prime number\n"
mov     w1, w20                          // w1 = n
bl      printf                           // Call printf(msg_not_prime, n)

// --------------------------------------------------------
// Exit function (restore stack and return)
// --------------------------------------------------------
.exit:
ldp     x19, x20, [sp], 16               // Restore x19, x20
ldp     x29, x30, [sp], 16               // Restore frame pointer and return address
mov     w0, #0                           // Return 0 from main
ret                                      // Return to OS