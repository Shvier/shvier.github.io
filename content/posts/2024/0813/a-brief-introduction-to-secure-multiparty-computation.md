+++
title = 'A Brief Introduction to Secure Multiparty Computation (MPC)'
date = 2024-08-13T17:00:30-04:00
tags = [
]
categories = [
]
series = [
]
isDraft = false
+++

## What Is MPC

MPC is a cryptographic protocol that allows some parties to perform some computing tasks while achieving 
* (i) *privacy*: no party can know anything except the output of the computation
* (ii) *correctness*: each party receives the correct output

While there are some other properties of MPC like *fairness*, I just listed the two most intuitive properties, and we will not discuss any security proofs for MPC as this is a simply explained post.

### Security Model

Formally, we need to indicate what assumptions we are using when solving problems. In MPC, there are two well-known models for security: semi-honest security and malicious security. In the semi-honest security model, even a corrupt party (corrupt party means the party plays the role of the attacker) follows the protocol correctly. The corrupt parties will try to learn as much as possible from the messages exchanged among other parties. We can also say passive adversary. On the other hand, malicious security means the adversaries do not need to follow the protocol but take any actions while exchanging messages. Although the semi-honest security model is a weak assumption as the real adversaries will not need to follow the protocol, it is the basic component for the protocols with more robust security.

## Preliminaries

In this section, I will introduce two cryptographic primitives, Shamir's secret sharing and oblivious transfer, as the MPC protocols in the following section heavily rely on these two primitives.

### Shamir's Secret Sharing

The basic idea of Shamir's secret sharing exploits the fact that interpolating a $d$-degree polynomial requires at least $d+1$ points. If we treat a polynomial $f$ as the secret (the evaluation of $f(0)$), then we just need to let each party hold an evaluation point of the polynomial. When all the parties share the point they hold, the polynomial can be reconstructed, which means they can know the secret $f(0)$. Formally, we call the number of required points to interpolate the polynomial **threshold**. If there are $n$ parties and any $k$ shares can reconstruct the polynomial, we say this is a $(k,n)$-threshold scheme.

#### Example

Suppose the secret is $S$, and we want a $(k,n)$-threshold scheme. Then we just need to generate a random polynomial with degree $k-1$ and let the constant term equal $S$. We use $f$ and $a_i$ to denote the polynomial and the coefficients respectively. So we have 
$$
f(x)=S+a_1x+a_2x^2+\cdots+a_{k-1}x^{k-1}
$$
Next, we evaluate $f$ for each party. Specifically, we compute $f(1),f(2),\dots,f(n)$ and distribute the evaluations to each party. By the Lagrange interpolation theorem, it is clear that any $k$ evaluation points are sufficient to reconstruct $f$.

### Oblivious Transfer

The oblivious transfer is a cryptographic protocol involving two parties, the sender $\mathcal{S}$ and the receiver $\mathcal{R}$, where $\mathcal{S}$ holds some secrets and $\mathcal{R}$ wants to retrieve one or more secrets while $\mathcal{S}$ does not know which secrets $\mathcal{R}$ chose. Here we will see the simplest version, a 1-out-of-2 oblivious transfer based on the discrete logarithm assumption (DLA), a.k.a, Bellare-Micali oblivious transfer[^1].

Let $\mathbb{G}$ be a group of prime order $p$ with a generator $g$. Let $H$ be a hash function. $\mathcal{S}$ holds two messages $m_0$ and $m_1$, and $\mathcal{R}$ has a selector bit $b\in\{0,1\}$. $\mathcal{R}$ wants to retrieve one of the messages by the selector $b$. $\mathcal{S}$ and $\mathcal{R}$ run the protocol as follows:

1. $\mathcal{S}$ randomly generates $c\stackrel{rand}{\leftarrow}\mathbb{G}_p$ and sends $c$ to $\mathcal{R}$.
2. $\mathcal{R}$ randomly chooses $k\stackrel{rand}{\leftarrow}\mathbb{Z}_p$ as the private key of the ElGamal private key, and computes two ElGamal public keys

$$y_b\leftarrow{g^k}$$
$$y_{1-b}\leftarrow\frac{c}{g^k}$$

3. $\mathcal{R}$ sends $y_0,y_1$ to $\mathcal{S}$.
4. $\mathcal{S}$ checks if $c$ equals $y_0\cdot{y_1}$. If not, $\mathcal{S}$ aborts the protocol.
5. $\mathcal{S}$ generates $r_0,r_1\stackrel{rand}{\leftarrow}\mathbb{Z}_p$ and computes two ElGamal ciphertexts using the public keys $y_0,y_1$, denoted by $c_0\leftarrow{(g^{r_0},H(y_0^{r_0})\oplus{m_0})}$ and $c_1\leftarrow{(g^{r_1},H(y_1^{r_1})\oplus{m_1})}$. $\mathcal{S}$ sends $c_0,c_1$ to $\mathcal{R}$.
6. $\mathcal{R}$ parses $c_b=(v_l,v_r)$ and decrypts $c_0,c_1$ using the knowledge of $k$: $m_b=H(v_l^k)\oplus{v_r}$.

Now $\mathcal{R}$ successfully retrieved $m_b$ and $\mathcal{S}$ does not know what $b$ is.

## The Concrete Approach

We can convert the computing tasks into polynomials for many cases in MPC like the above example of Shamir's secret sharing. In complexity theory, we are interested in the arithmetic circuit model to compute polynomials because it suffices to perform any computation if the addition gate and the multiplication gate can be computed (may be not efficient in some cases but optimization can be applied). While Yao's Garbled Circuit (GC) is considered the most widely known MPC protocol, I will introduce the BGW protocol first as it is relatively easier to understand.

### BGW Protocol

In BGW protocol, there are two parties, say, Alice and Bob, computing an arithmetic circuit with their secrets as inputs. The rule is Alice and Bob cannot know each other's secret and they both get the output of the circuit. We use $\alpha$ and $\beta$ to denote their secrets respectively. 

First, consider the addition gate, with input $\alpha$, $\beta$ and output $\gamma$. Alice generates a $1$-degree polynomial $f_1$ such that $f_1(0)=\alpha$ and Bob computes $f_2$ such that $f_2(0)=\beta$. So the question becomes how to compute a polynomial $f$ such that $f=f_1+f_2$ since $\gamma=f(0)=f_1(0)+f_2(0)=\alpha+\beta$. But they cannot compute $f$ directly by exchanging $f_1,f_2$ because this way leaks $\alpha$ and $\beta$. Instead, Alice evaluates $f_1$ at two points $x_1$ and $x_2$, and sends $f_1(x_2)$ to Bob. Similarly, Bob sends $f_2(x_1)$. Note this does not violate the rule because $1$-degree polynomial requires two points to be interpolated, which means Alice cannot learn $\beta$ with $f_2(x_1)$, and neither does Bob learn $\alpha$ with $f_1(x_2)$. Now Alice has $f_1(x_1),f_2(x_1)$ and Bob has $f_1(x_2),f_2(x_2)$, and they want to compute $\gamma=f_1(0)+f_2(0)$. It can be observed that when they add the two values they hold, they can construct a new polynomial, and the new polynomial is identical to $f$! Specifically, let Alice compute $\alpha^\prime=f_1(x_1)+f_2(x_1)$ and Bob compute $\beta^\prime=f_1(x_2)+f_2(x_2)$, and they interpolate a polynomial $f^\prime$ from $\alpha^\prime$ and $\beta^\prime$. The reason why $f^\prime$ equals $f$ is the fact that a polynomial can be represented as coefficient form and evaluation form interchangeably. In other words, when we add two polynomials, it is equivalent to adding the evaluations at the same point of the polynomials, which is exactly the way that Alice and Bob do.

However, the fact cannot be leveraged directly for multiplication gate because multiplication increases the degree of the polynomial. Recall that the threshold relates to the degree, which means the points that Alice and Bob hold are not sufficient to reconstruct the polynomial $f$. To get around this issue, BGW utilized a tricky way to reduce the degree. The basic idea is, instead of $n$ parties recovering a $2n$-degree polynomial, let $2n+1$ parties distribute a $n$-threshold sharing of their secret to reduce the degree of $f$ to $n$. Why does this work? First, $2n+1$ points can reconstruct the $2n$-degree polynomial $f$. Second, the points of $f$ are $n$-threshold sharing, which means any $n$ parties among the whole set can recover $f$.

### Yao's Garbled Circuit

Unlike the idea that the BGW protocol exploits the Lagrange interpolation theorem, Yao's GC approach converts a polynomial into a lookup table. That is, we can create a lookup table for all the evaluations of the polynomial such that the two parties' inputs are the entry. If such a lookup table exists, Alice and Bob just need to run a 1-out-of-n oblivious transfer to find the result at the correct position of the table for each evaluation time. There are two parties in Yao's GC, one for garbling the circuit, and the other for evaluating the circuit. Before we dive into the general 2PC, let us see a simple case, the AND gate.

Suppose Alice holds a bit $b_0$ and Bob holds a bit $b_1$. Alice and Bob want to evaluate the AND result of $b_0$ and $b_1$. They do not want each other to know their own input. Alice plays the role of garbling the circuit, and Bob plays the role of the evaluator. Given the truth table of the AND gate, they run the protocol as follows:

1. Alice generates a pair of keys $(k_l^0,k_l^1),(k_r^0,k_r^1)$.
2. Alice encrypts the table of the AND gate using the above keys such that
$$
c_{00}=E_{k_l^0,k_r^0}(0) \\
c_{01}=E_{k_l^0,k_r^1}(0) \\
c_{10}=E_{k_l^1,k_r^0}(0) \\
c_{11}=E_{k_l^1,k_r^1}(1)
$$
3. Alice sends the 4 ciphertexts to Bob.
4. In order to let Bob evaluate the AND gate, Bob needs to know the private key of Alice's input and his input. For Bob's key, Alice cannot send the key to Bob directly because this will tell Alice what Bob's input is. Recall the above oblivious transfer, so Alice and Bob run a 1-out-of-2 oblivious transfer for $(k_r^0,k_r^0)$. For Alice's key, she simply sends the key to Bob.
5. Bob decrypts the ciphertexts with the two keys he received. He should compute one correct message and others are garbage.

Now we can extend the above protocol for the AND gate to any function. Suppose Alice and Bob want to evaluate a polynomial $f(x,y)$, where $x$ is Alice's input, $y$ is Bob's input, and $f$ is a general function: $\\{0,1\\}^n\times\\{0,1\\}^n\rightarrow\\{0,1\\}^*$.

1. Alice converts the evaluations of $f$ into a lookup table such that the first column is the possible values of Alice's input $x_i$, the second column is the possible values of Bob's input $y_j$, and the third column is the evaluation of $f(x_i,y_j)$.
2. Alice encrypts the lookup table by randomly generating a key to each possible input $x$ and $y$ like she did for the AND gate table.
3. Alice sends her key to Bob.
4. Alice and Bob run a 1-out-of-|$y_j$| oblivious transfer to let Bob retrieve his key.
5. Bob decrypts the table with the two keys.

Note the MPC protocol in practice requires more robust techniques since the evaluator will know the garbler's input when he successfully decrypts the ciphertext. To solve this, the garbler normally shuffles the encrypted table. Another issue is it is not efficient for the evaluator to decrypt the table row by row. To get around this, we can interpret the partial information of the key as a pointer to the table. The together two improvements are often point-and-permute.

## Further Reading

1. [Lecture by Tal Rabin](https://www.youtube.com/watch?v=NOtsxHoIcWQ&list=PLtieFm4iy3qA6Q86APv90-3CYgz7fWzVg)
2. [The MPC Book](https://securecomputation.org/)

[^1]: https://crypto.stanford.edu/cs355/18sp/lec6.pdf
