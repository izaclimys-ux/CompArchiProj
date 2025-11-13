print("Please input first number: ")
num1 = int(input())  # user input
print("Please input second number: ")
num2 = int(input())  # user input
print("Please input third number: ")
num3 = int(input())  # user input


largest = [num1, num2, num3]  # assume the first number is the largest

for n in largest:
    if n >= max(largest):
        largest_num = n
print(f'The largest number is {largest_num}')  # output the largest number
