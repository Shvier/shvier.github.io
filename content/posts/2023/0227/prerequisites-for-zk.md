+++
title = 'Prerequisites for ZK'
date = 2023-02-27T16:49:24-05:00
tags = [
    "Cryptography",
    "Math",
    "ZKP"
]
categories = [
]
series = [
]
isDraft = true
+++

## Preface
I started my research on ZKP last month. There were many unfamiliar math concepts for me, such as group, order, elliptic curve, etc. After struggling for several days and with the help of my professor, I understood them gradually. Now I want to construct my knowledge base in this field. My best bet is to rephrase these contents like executing rubber duck debugging. This is why I decided to write a series of articles to help me review the ideas.
This page is aiming at introducing jargon/concepts and explaining them with concrete examples (try my best). For some complicated concepts, I'll illuminate the topics with more pages.

### Field
> A field is a set, whose elements are able to execute basic number operations with each other, denoted by an upper character (\\(\mathbb F\\)).

#### e.g.
* \\(\mathbb R\\) (real numbers)
* \\(\mathbb Q\\) (rational numbers)

Most cryptographic theorems reply on finite fields, especially with prime numbers. The reason is that the modulo operation over prime numbers features some useful properties. I'll introduce these features and how they work later.

### Group
> A group is a set and a binary operation * that allows any two elements to produce a third element, which also belongs to the same set, denoted by \\((\mathbb G, *)\\).

#### e.g.
* \\((\mathbb Q, +)\\), \\(\mathbb Q\\) under \\(+\\) operation is a group.

A group has the following properties:
* **Closure**: \\(\forall a,b\in\mathbb G, a*b\in\mathbb G\\). I.e., the definition of a group.
* **Associativity**: \\(\forall a,b,c\in\mathbb G, (a\*b)\*c=a\*(b\*c)\\). E.g., For addition, \\((a+b)+c=a+(b+c)\\).
* **Identify**: There exists a unique element \\(e\in\mathbb G\\), s.t. \\(\forall a\in\mathbb G,e\*a=a\*e=a\\). E.g., \\(1\\) is the identity of multiplication, \\(0\\) is the identity of addition.
* **Inverse**: \\(\forall a\in\mathbb G\\), there exists a unique element \\(b\in\mathbb G\\), s.t. \\(a\*b=b\*a=e\\). Such element is called the inverse of \\(a\\) and commonly denoted by \\(a^{-1}\\).

In applied cryptography, a group over modular multiplicative with prime numbers is frequently used. This is because \\(1\\) is the identity element in the multiplication group, and finding the inverse of an element is equivalent to solving (ax\equiv 1\space (mod\space p)\\), which is the goal of the Extended Euclidean algorithm. The benefits for computers to implement cryptographic algorithms through modular multiplicative are boosting the computation process and reducing memory usage. Recall RSA, the public key \\(e\\) is the inverse of the private key \\(d\\) modulo \\(\phi(N)\\).

### Subgroup
> A subgroup is a non-empty subset of a group, denoted by \\((\mathbb S, *)<(\mathbb G, *)\\).

#### e.g.
* \\((\mathbb Z, +)<(\mathbb Q, +)\\), integers \\(\mathbb Z\\) is a subgroup of rational numbers \\(\mathbb Q\\) under \\(+\\).

**Note**:
* A subgroup has all the properties of a group.
* A group is a subgroup of itself.
* The set containing the single identity element is also a subgroup, called a trivial subgroup.

### Order
> The order of a group is the number of elements in that group, denoted by \\(|\mathbb G|\\).
> The order of an element is the smallest positive integer 

### Generator


As for cryptography, a group under exponentiation is more commonly used. E.g., \\(3\\) is a generator of 

### Safe Prime
> A safe prime is a prime number \\(p\\), s.t. \\(p=2q+1\\) where q is also prime.

#### e.g.

* \\(5\\) is a safe prime (\\(5=2\times2+1\\))
* \\(7\\) is a safe prime (\\(7=2\times3+1\\))

### Polynomial

### Lagrange Interpolation

### Discrete Logarithm

### Diffie-Hellman Key Exchange

### Fiat-Shamir Heuristic

### Elliptic Curve

### Pairing
