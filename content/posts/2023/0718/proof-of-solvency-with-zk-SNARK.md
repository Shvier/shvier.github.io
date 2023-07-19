+++
title = 'Proof of Solvency with zk SNARKs, Re-explained'
date = 2023-07-17T17:01:02-04:00
tags = [
]
categories = [
]
series = [
]
isDraft = false
+++

This is a re-exposition of [Vitalik's customized IOP](https://vitalik.ca/general/2022/11/19/proof_of_solvency.html#improving-privacy-and-robustness-with-zk-snarks) about proof of solvency. The protocol was intuitive when I first read it, so I didn't think about the details thoroughly. When I was designing a protocol of proof of solvency, I wanted to compare the pros and cons of the existing designs. So this post came out.

## KZG commitment

KZG is one of the most prevalent polynomial commitments. It is widely used in generating proof of zero knowledge. How can we do that? A polynomial commitment is a "hash" of a function. The prover converts the problem into one or several polynomials and commits to them, i.e., hashes the polynomials, and sends them to the verifier. Then the verifier randomly chooses a challenge and replies to the prover. The prover computes the result at the challenge point and reveals it to the verifier. If the result matches with the value computed from the commitment, the prover proves he knows the polynomial, that is, the solution to the problem. In this and the original article, the polynomial commitment is denoted by \\(P(x)\\).

## Auxiliary polynomial

Vitalik introduced an auxiliary polynomial \\(I(x)\\) to build the proving system. Specifically, the following equations hold to prove the solvency (strictly speaking, it is proof of liability):
* \\(I(z^{16x})=0\\)
* \\(I(z^{16x+14})=P(\omega^{2x+1})\\)
* \\(I(z^i)-2*I(z^{i-1})\in\\{0,1\\},\text{ if }i\mod{16}\notin\\{0,15\\}\\)
* \\(I(z^{16x+15})=I(z^{16x-1})+I(z^{16x+14})-{\text{the declared total}\over\text{user count}}\\)

Let us check out these equations one by one.
1. \\(I(z^{16x})=0\\) and \\(I(z^i)-2*I(z^{i-1})\in\\{0,1\\}\\) proves that \\(I\\) stores the binary bits of each balance, which is assumed under \\(2^{15}\\). \\(I(z^{16x})=0\\) is not mandatory to achieve proof of liability. What it makes is ensuring the balance is exactly lower than \\(2^{15}\\). If we omit this equation, the range constraint will be \\(2^{15}+1\\).
2. \\(I(z^{16x+14})=P(\omega^{2x+1})\\) is actually a copy constraint, which makes all balances the same as those in the original data set. For example, \\(P(\omega^3)=50\\) and \\(I(z^{30})=50\\) when \\(x=1\\).
3. The last equation is the most tricky part of this proposal. From the original post, the declared total is \\(1480\\), and the user count is \\(8\\). Let \\(x=1\\), we have \\(I(z^{31})=-300,I(z^{15})=-165,I(z^{30})=50\\), which satisfies the equality. That is, `every 16th position tracks a running total with an offset so that it sums to zero` comes from. However, I have to point out the prover can choose an arbitrary value instead of the actual amount, which still can pass the verifying process. Since exchanges always want to lower their liabilities to prove they have enough funds, they do not have any reason to increase the amount. For example, if we change the declared total to 1000, \\(I(z^{14})=20,I(z^{15})=-105,I(z^{30})=50,I(z^{31})=-35\\), the equation still holds. But it can be easily mitigated by adding a constraint that \\(I(z^x)\gt 0\\).

## Related work

The biggest issue of the proposal is that it requires a big trusted setup, fully described in this [post](https://ethresear.ch/t/snarked-merkle-sum-tree-a-practical-proof-of-solvency-protocol-based-on-vitaliks-proposal/14405#very-large-trusted-setup-9). 

One of the optimizations is separating the users into several groups, and we generate the proof of liability for each group, then compute the proof of each group's liability.
