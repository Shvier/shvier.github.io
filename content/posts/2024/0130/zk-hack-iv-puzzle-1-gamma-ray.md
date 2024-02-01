+++
title = 'ZK Hack IV Puzzle 1: Gamma Ray'
date = 2024-01-30T14:43:31-05:00
tags = [
]
categories = [
]
series = [
]
isDraft = false
+++

> Bob was deeply inspired by the Zcash design [^1] for private transactions and had some pretty cool ideas on how to adapt it for his requirements. He was also inspired by the Mina design for the lightest blockchain and wanted to combine the two. In order to achieve that, Bob used the MNT6753 cycle of curves to enable efficient infinite recursion, and used elliptic curve public keys to authorize spends. He released a first version of the system to the world and Alice soon announced she was able to double spend by creating two different nullifiers for the same key...

## Puzzle Explanation

We can find Bob's implementation of the spend transaction verification starting from [line 78](https://github.com/ZK-Hack/puzzle-gamma-ray/blob/main/src/main.rs#L78). Specifically, he builds a Merkle tree with the parameters from the circuit inputs (lines 78-94); then he validates the witness (private input), the secret key (\\(s\\)), less than the `MNT6BigFr` modulus (lines 96-98); next, he checks the hash value of the secret is equal to the public input, `nullifier` (lines 100-107); finally, he computes the public key through the scalar multiplication, \\(s\cdot{G}\\), and verifies the x coordinate of the public key is the member of the tree.  
Thus, what the puzzle is asking is to find another `nullifier` that still satisfies the circuit.

## The Breakdown

The difference between Bob's implementation and Zcash is the elliptic curve. The curve that Zcash uses is a complete twisted Edwards elliptic curve, with the equation: \\(a\cdot{x^2}+y^2=1+d\cdot{x^2}\cdot{y^2}\\) [^1]. Here I linked what a possible ctEdwards looks like in Figure 1.
![](https://upload.wikimedia.org/wikipedia/commons/thumb/3/3c/Edward-curves.svg/2880px-Edward-curves.svg.png)
*Figure 1. Edwards curves of equation x2 + y2 = 1 − d ·x2·y2 over the real numbers for d = 300 (red), d = √8 (yellow) and d = −0.9 (blue) [^2]*

It is easy to see that any point excluding \\((0,\pm 1)\\) on the curve has order 4 with elements in the defined field, \\(\mathbb{J}\\). However, in Zcash, what is actually used is the subgroup of order, a prime number \\(r_\mathbb{J}\\), which implies the point \\((0,-1)\\) does not exist in \\(\mathbb{J}^{(r)}\\), since the order of \\((0,-1)\\) is 2 in \\(\mathbb{J}\\). With this fact and some other inductions, we can prove the Lemma 5.4.7 in Zcash. Therefore, it is secure to only validate the x coordinate of the point because each point is injective in \\(\mathbb{J}^{(r)}\\), i.e, given a valid point \\((u,v)\\), \\((u,-v)\\) is invalid.   
On the contrary, in Bob's implementation, the curve is Miyaji–Nakabayashi–Takano, which is in Weierstrass form. That means \\((u,-v)\\) is valid if \\((u,v)\\) exists.

## The Solution

Based on the above exploration, the solution is clear to be found: compute the \\((x,-y)\\) by inverting \\(s\cdot{G}\\) and hash the result to get the new `nullifier`.
    ```rust
    let inv_secret = -MNT6BigFr::from(leaked_secret.into_bigint());
    let secret_hack = MNT4BigFr::from(inv_secret.into_bigint());
    let nullifier_hack = <LeafH as CRHScheme>::evaluate(&leaf_crh_params, [secret_hack]).unwrap();
    ```

[^1]: https://zips.z.cash/protocol/protocol.pdf
[^2]: https://en.wikipedia.org/wiki/Edwards_curve
