coins = [1, 2, 5, 10, 20, 50, 100, 200]

goal = 40

import copy

def value(soln):
  value = 0
  for k, v in soln.items():
    value += k * v
  return value
    
working = []
working.append({1:0, 2:0, 5:0, 10:0, 20:0, 50:0, 100:0, 200:0})
done = []
seen = []

while True:
  if len(working) == 0:
    break
  soln_orig = working.pop()
  seen.append(soln_orig)
  for coin in coins:
    soln = copy.copy(soln_orig)
    soln[coin] += 1
    v = value(soln)
    #print(f"val of {soln} is {v}")
    if v < goal:
      if soln not in seen:
        if soln not in working:
          print(f"got soln {soln} of value {v}")
          working.append(soln)
          print(len(working))
    if v == goal:
      if soln not in done:
        done.append(soln)

print(len(done))
