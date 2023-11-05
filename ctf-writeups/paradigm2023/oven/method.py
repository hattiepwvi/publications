# a set of tools for interacting with binary programs and network services in CTF competitions
from pwn import *
# cryptography function: e.g. converting between integers and bytes
from Crypto.Util.number import *
from tqdm import trange
​
# a connection to a remote server with the address "oven.challenges.paradigm.xyz" on port 1337.
conn = remote("oven.challenges.paradigm.xyz", 1337)
​
def get_arg(v):
    # wait for a specific prompt from the server
    # receives data from the connection conn until it encounters the string formed by concatenating the value of v and the string " = "
    conn.recvuntil(f'{v} = '.encode())
    # returning an integer received from the server
    # removes any leading or trailing whitespace, decodes it from bytes to a string, and then converts it to an integer
    return int(conn.recvline().strip().decode())
​
def parse():
    t = get_arg('t')
    r = get_arg('r')
    p = get_arg('p')
    g = get_arg('g')
    y = get_arg('y')

    return t, r, p, g, y
​
# a custom hash function: processes input data n and returns a hash value
def custom_hash(n):
    state = b"\x00" * 16
    for i in range(len(n) // 16):
        state = xor(state, n[i : i + 16])
​
    for _ in range(5):
        state = hashlib.md5(state).digest()
        state = hashlib.sha1(state).digest()
        state = hashlib.sha256(state).digest()
        state = hashlib.sha512(state).digest() + hashlib.sha256(state).digest()
​
    value = bytes_to_long(state)
​
    return value
​
arr = []
​
for _ in trange(20):
    # sends the byte string b'1' to the connection conn after waiting for the string
    conn.sendlineafter(b'Choice: ', b'1')
    t, r, p, g, y = parse()
​
    c = custom_hash(long_to_bytes(g) + long_to_bytes(y) + long_to_bytes(t))
​
    arr.append((c, r, p))
​
​
mat = []
​
# negating the first element of each tuple in arr.
# concatenates the list generated in step 1 with the list [1, 0]
mat.append([ -it[0] for it in arr ] + [1, 0])
​
# LLL (Lenstra-Lenstra-Lovász) algorithm
for i in range(20):
    row = [0] * i + [ arr[i][2] - 1 ] + [0] * (20 - i) + [0]
    mat.append(row)
​
mat.append([ -it[1] for it in arr ] + [0, 2^512])
​
# constructs a matrix mat based on the elements in arr
mat = Matrix(mat)
​
res = mat.LLL()
​
for row in res:
    t = int(row[-2])
    if t < 0:
        # making it non-negative
        t = -t
    print(long_to_bytes(t))


# summary: interacting with a server that knows a FLAG value and performs cryptographic operations upon request, outputting computed values
    # 1) uses a technique called Fiat Shamir on the FLAG
        # these techniques are used to generate Zero-Knowledge Proof
        # the server was actually generating a proof that it knows the FLAG
        # we play the role of the verifier.
    # 2) the Hidden Number Problem: to leak the secret of a Fiat Shamir proof if the randomness used during the proof generation is not strong enough.
        # v is a random value chosen in the range [2, 2**256]
            # v has a size of 512 bits at most, which is way lower than the p - 1 value as p is a prime of 1024 bits.
            # construct a lattice to recover the flag value using the relation r_i = (v_i - c_i * FLAG) % (p_i - 1) only with c_i, r_i, and p_i
    # 3) solution: vector problem (CVP) solved using Babai’s nearest plane algorithm + the LLL lattice reduction algorithm
        # A lattice is a space you can define based on a set of points in which you can move by adding/substracting points as much as you want.
        # use the (magic) LLL algorithm to find a short solution vector for v, ultimately leading us to the FLAG
