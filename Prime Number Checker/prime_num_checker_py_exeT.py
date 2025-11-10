import time # Import the time module

print('Please input a number: ')
num = int(input()) #user input

start_time_us = time.perf_counter_ns()//1000 # Record the start time in nanoseconds

s = int(num**.5) #converting float to integer for range function

if num > 1: #checking if number is either 1 or greater than 1
    for i in range(2, s+1): #checks for factors from 2 to num-1
        if (num % i) == 0: #checks for each factor
            print(f'{num} is not a prime number')
            break
    else: # This 'else' belongs to the 'for' loop, meaning no break was encountered
        print(f'{num} is a prime number')
else:
    print(f'{num} is not a prime number') #output if equal to 1

end_time_us = time.perf_counter_ns() // 1000 # Record the end time in nanoseconds
execution_time_us = end_time_us - start_time_us
print(f"Execution time: {execution_time_us} microseconds")
