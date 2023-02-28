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

# Preface
I started my research on ZKP last month. There were many unfamiliar math concepts for me, such as group, order, elliptic curve, etc., and I couldn't fully understand them even with the help of my professor. After struggling for several days and reading some papers, I want to construct my knowledge base in this field. My best bet is to rephrase these contents like executing rubber duck debugging. This is why I decided to write a series of articles to help me review the ideas.
This page is aiming at introducing jargon and explaining them with concrete examples. For some complicated concepts, I'll illuminate the topics with more papers.

# Math

## Field
> A field is a set, whose elements are able to execute basic number operations with each other.

We usually use an upper character to denote a field. e.g., \\(\mathbb R\\) (real numbers), \\(\mathbb Q\\) (rational numbers).

Most cryptographic theorems reply on finite fields, especially with prime numbers. The reason is that the modulo operation over prime numbers features some useful properties. We'll see how these features work later.

## Group
> A group is a set and an operation * that allows any two elements to produce a third element, which also belongs to the same set.

A group has the following properties:
* **Closure**: \\(\forall a,b\in\mathbb G, a*b\in\mathbb G\\). i.e., the definition of a group.
* **Associativity**: \\(\forall a,b,c\in\mathbb G, (a\*b)\*c=a\*(b\*c)\\). e.g., For addition, \\((a+b)+c=a+(b+c)\\).
* **Identify**: There exists a unique element \\(e\in\mathbb G\\), s.t. for each \\(a\in\mathbb G,e\*a=a\*e=a\\). e.g., \\(1\\) is the identity of multiplication, \\(0\\) is the identity of addition.
* **Inverse**: For each \\(a\in\mathbb G\\), there exists a unique element \\(b\in\mathbb G\\), s.t. \\(a\*b=b\*a=e\\). Such element is called the inverse of \\(a\\) and commonly denoted by \\(a^{-1}\\).

### e.g.

* \\(\mathbb Q\\) under \\(+\\) operation is a group.

## Generator

## Order

## Subgroup

## Polynomial

# Cryptography

## Prime Number

## Discrete Logarithm

## Diffie-Hellman Key Exchange

## Fiat-Shamir Heuristic

## Safe Prime
> A safe prime is a prime number \\(p\\), s.t. \\(p=2q+1\\) where q is also prime.

### e.g.

* \\(5\\) is a safe prime (\\(5=2\times2+1\\))
* \\(7\\) is a safe prime (\\(7=2\times3+1\\))

## Elliptic Curve

## Pairing
