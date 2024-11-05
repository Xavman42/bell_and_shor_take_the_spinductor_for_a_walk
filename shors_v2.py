import math
import random
import itertools
from prime_test import brute_force_prime_test


# Brute force period finding algorithm
def find_period_classical(x, N):
    n = 1
    t = x
    while t != 1:
        t *= x
        t %= N
        n += 1
    return n


# Sieve of Eratosthenes algorithm
def sieve():
    D = {}
    yield 2
    for q in itertools.islice(itertools.count(3), 0, None, 2):
        p = D.pop(q, None)
        if p is None:
            D[q * q] = q
            yield q
        else:
            x = p + q
            while x in D or not (x & 1):
                x += p
            D[x] = p


# Creates a list of prime numbers up to the given argument
def get_primes_sieve(n):
    return list(itertools.takewhile(lambda p: p < n, sieve()))


def get_semiprime(n):
    primes = get_primes_sieve(n)
    l = len(primes)
    p = primes[random.randrange(l)]
    q = primes[random.randrange(l)]
    return p * q


def shors_algorithm_classical(N):
    guess = random.randint(1, N)  # step one
    if math.gcd(guess, N) != 1:  # step two
        return guess, 0, math.gcd(guess, N), N / math.gcd(guess, N)
    r = find_period_classical(guess, N)  # step three
    while r % 2 != 0:
        guess = random.randint(1, N)  # step one
        if math.gcd(guess, N) != 1:  # step two
            return guess, 0, math.gcd(guess, N), N / math.gcd(guess, N)
        r = find_period_classical(guess, N)
    p = math.gcd(guess ** int(r / 2) + 1, N)  # step four, ignoring the case where (x^(r/2) +/- 1) is a multiple of N
    q = math.gcd(guess ** int(r / 2) - 1, N)
    return guess, r, p, q


def factorize(N):
    given = N
    primes = []
    primes_found = False
    if brute_force_prime_test(N):
        primes_found = True
        # print(N, " is prime!")
        primes.append(N)
        return primes
    while not primes_found:
        x, r, p, q = shors_algorithm_classical(N)
        p = int(p)
        q = int(q)
        if p != N and p != 1:
            if brute_force_prime_test(p):
                primes.append(p)
                N = int(N / p)
        if q != N and q != 1:
            if brute_force_prime_test(q):
                primes.append(q)
                N = int(N / q)
        if brute_force_prime_test(N):
            primes.append(N)
            # print("number:", given, "primes:", primes)
            return primes
        # print(given, p, q, N)


if __name__ == "__main__":
    for number in range(1, 5000):
        factorize(number)
