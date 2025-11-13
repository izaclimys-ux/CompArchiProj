#include <stdio.h>

void largest(int a, int b, int c);
int main() {

    int num1, num2, num3;
    /* Input three numbers from the user */
    printf("Enter three numbers: ");
    scanf("%d %d %d", &num1, &num2, &num3);
    largest(num1, num2, num3);

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