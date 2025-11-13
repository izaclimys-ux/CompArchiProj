import time # Import the time module

print("Please input first number: ")
num1 = int(input())  # user input
print("Please input second number: ")
num2 = int(input())  # user input
print("Please input third number: ")
num3 = int(input())  # user input

start_time_us = time.perf_counter_ns()//1000 # Record the start time in nanoseconds


largest = [num1, num2, num3]  # assume the first number is the largest

for n in largest:
    if n >= max(largest):
        largest_num = n
print(f'The largest number is {largest_num}')  # output the largest number

end_time_us = time.perf_counter_ns() // 1000 # Record the end time in nanoseconds
execution_time_us = end_time_us - start_time_us
print(f"Execution time: {execution_time_us} microseconds")
