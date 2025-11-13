import time # Import the time module

# Record the start time
start_time = time.time()

print("Please input first number: ")
num1 = int(input())  # user input
print("Please input second number: ")
num2 = int(input())  # user input
print("Please input third number: ")
num3 = int(input())  # user input

largest = [num1, num2, num3]

# Using max() directly is more efficient
largest_num = max(largest)

print(f'The largest number is {largest_num}')

# Record the end time
end_time = time.time()

# Calculate the execution time
execution_time = end_time - start_time

print(f"Execution time: {execution_time:.4f} seconds")