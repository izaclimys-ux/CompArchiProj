#include <stdio.h>
#include <math.h>
#include <time.h> // Include for time functions

void prime_check(int x);

int main(){
    /*initialise values*/
    int x;
    clock_t start_time, end_time; // Variables to store start and end clock times
    double cpu_time_used;         // Variable to store the elapsed time in seconds

    /*ask for input*/   
    printf("please input a number: ");
    scanf("%d", &x);

    // Record the start time
    start_time = clock();

    prime_check(x);

    // Record the end time
    end_time = clock();

    // Calculate the elapsed CPU time
    // CLOCKS_PER_SEC is a macro that represents the number of clock ticks per second
    cpu_time_used = ((double) (end_time - start_time)) / CLOCKS_PER_SEC;

    printf("Execution time: %f seconds\n", cpu_time_used);

    /*output*/
    return 0;
}

void prime_check(int x)
{
    int xyz = 0; 

    /* if input is 1 OR greater than 2 AND remainder of input mod 2 is equal to 0*/
    /* then input is a not prime number*/
    if (x <= 1 || ((x > 2) && (x%2 == 0)))
        printf("%d is a not prime number\n", x);
    else
        if (x==2)
        {
            printf("%d is a prime number\n", x);
        }
        else{
            // Optimization: No need to check for even numbers in the loop since we already handled x%2==0
            for (int i = 3; i * i <= x; i+=2) /*finding prime by increasing divisor up to sqrt(x)*/
            {
                if (x % i== 0)
                    xyz++;
            }
             if (xyz > 0)
            {
                printf("%d is not prime number\n", x);
            }
            else
            {
                printf("%d is prime number\n", x);
            }
        }
}