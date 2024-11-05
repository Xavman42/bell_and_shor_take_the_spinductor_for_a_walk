import numpy as np


def prime_test(p):
    if p > 2 and int(p/2) == p/2:
        # print(p, " is not a prime")
        return False
    y = [1, -1]
    for i in range(p-1):
        y = np.polymul(y, [1, -1])
    z = [0] * (p+1)
    z[0] = 1
    z[p] = -1
    y = np.polysub(y, z)
    # print(y)
    for i in range(len(y)):
        x = y[i]
        test = x/p
        print(test)
        if int(test) == test:
            pass
        else:
            # print(p, " is not a prime")
            return False
    print(p, " is prime!")
    return True


def brute_force_prime_test(p):
    p = int(p)
    if p < 4:
        # print(p, " is prime!")
        return True
    for i in range(2, p-1):
        if int(p/i) == p/i:
            # print(p, " is not a prime")
            return False
    # print(p, " is prime!")
    return True


if __name__ == "__main__":
    for j in range(1000):
        if brute_force_prime_test(j+1):
            print(j+1)

