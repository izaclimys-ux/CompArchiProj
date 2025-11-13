#include <stdio.h>
#include <time.h> // Include the time header

void largest(int a, int b, int c);

int main() {
    clock_t start_time, end_time; // Declare variables to store start and end times
    double cpu_time_used;         // Declare variable to store the CPU time used

    int nums[3];  // array to store 3 numbers

    /* Ask for input using a for loop */
    for (int i = 0; i < 3; i++) {
        printf("Enter number %d: ", i + 1);
        scanf("%d", &nums[i]);
    }

    start_time = clock(); // Record the starting time

    /* Call the function to find and print the largest number */
    largest(nums[0], nums[1], nums[2]);

    end_time = clock(); // Record the ending time

    // Calculate the CPU time used
    cpu_time_used = ((double)(end_time - start_time)) / CLOCKS_PER_SEC;

    printf("Execution time: %f seconds\n", cpu_time_used);

    return 0;
}

void largest(int a, int b, int c) {
    int largest;

    /* Determine the largest number */
    if (a >= b && a >= c) {
        largest = a;
    } else if (b >= a && b >= c) {
        largest = b;
    } else {
        largest = c;
    }

    /* Output the result */
    printf("The largest number is: %d\n", largest);
}