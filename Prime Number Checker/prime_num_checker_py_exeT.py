import time

# Record the start time
start_time = time.time()

print('Please input a number: ')
num = int(input()) #user input

s = int(num**.5) #converting float to integer for range function

if num > 1: #checking if number is either 1 or greater than 1
    for i in range(2, s+1): #checks for factors from 2 to num-1
        if (num % i) == 0: #checks for each factor
            print(f'{num} is not a prime number')
            break
    else:
        print(f'{num} is a prime number')
else:
    print(f'{num} is not a prime number') #output if equal to 1

# Record the end time
end_time = time.time()

# Calculate the execution time
execution_time = end_time - start_time

print(f"Execution time: {execution_time:.4f} seconds")