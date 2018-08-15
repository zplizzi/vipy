
n = 10

threes = list(range(0, n, 3))
fives = list(range(0, n, 5))

result = set(threes + fives)

print(sum(result))

