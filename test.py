import math
import numpy as np

def is_palindrome(i):
  s = str(i)
  for i in range(len(s) // 2):
    if s[i] != s[-(i+1)]:
      return False
  return True

res = []
for i in range(1000):
  for j in range(1000):
    if is_palindrome(i*j):
      res.append(i * j)

print(max(res))
