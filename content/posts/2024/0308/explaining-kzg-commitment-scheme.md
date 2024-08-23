+++
title = 'Explaining KZG Commitment Scheme'
date = 2024-03-08T20:05:35-05:00
tags = [
]
categories = [
]
series = [
]
isDraft = true
+++

## Commitment Scheme

In zero-knowledge proofs, the prover normally commits to the statement he wants to prove and reveals the commitment later. Since he cannot tamper with the commitment, the soundness of a ZKP is guaranteed. This is the basic idea of a commitment scheme. In modern zkSNARKs, we can commit to the data in any type. KZG is a commitment scheme for polynomials. That is, the prover commits to a polynomial and reveals a random evaluation point. If the evaluation is correct, the verifier can believe the prover knows such a polynomial with significant confidence due to the Schwartz-Zippel lemma.

## Polynomial Interpolation

To prove the statement is correct, the first thing that the prover needs to do is construct the polynomial. We know a polynomial can be represented in two forms, coefficient and point-value. The KZG commitment scheme works with the coefficients, which means the prover has to convert the evaluations into coefficients first. This is where the polynomial interpolation comes from. There are some commonly known ways of interpolating a polynomial like, the Lagrange interpolation, the Newton interpolation, and the Vandermonde matrix. I will not explain the details of these methods in this post. See [this post](../../0820/polynomial-interpolation-and-fft) if you are interested in polynomial interpolation. It is worth noting the polynomial interpolation normally works with the fast Fourier transform (FFT) and root of unity for the efficiency. 

## Elliptic Curve and Pairing

By the discrete logarithm assumption (DL), the Pedersen commitment features binding and perfect hiding. The idea of KZG commitment scheme is use the Pedersen commitment to commit to the coefficients of the polynomial. Suppose $\{a_0,a_1,a_2,\dots,a_{n-1}\}$ are the coefficients of $f$, the KZG commitment to $f$ is $g^{a_0+\tau{a_1}+\tau^2{a_2}+\cdots+\tau^{n-1}a_{n-1}}$. Due to DL, it is infeasible for one to compute $\tau$ given $\{g,g^{\tau},g^{\tau^2},\dots,g^{\tau^{n-1}}\}$, which is why the KZG commitment scheme requires a trusted setup to publish the tau thing in advance. In practice, you may want to add an extra polynomial, somewhere call it the mask polynomial, to improve the security of the commitment. Specially, we need to generate another generator $h$ on the same field and the relation between $g$ and $h$ should not be known to any party. We use this $h$ to commit to a randomly generated polynomial with the same degree as $f$. Let call it $\hat{f}$. So the commitment will be $g^{f(\tau)}h^{\hat{f}(\tau)}$.

It seems good so far but we cannot do anything with this commitment $g^{f(\tau)}h^{\hat{f}(\tau)}$ because only addition exists in DL. That is, we have to know the $x$ or $y$ if we want to compute $g^{xy}$ given $g^x,g^y$; we get $g^{x+y}$ if we multipily $g^x$ and $g^y$ (the computational Diffie-Hellman, CDH). Why is multiplication so important? The reason is we exploit the Schwart-Zippel lemma to verify the polynomial is correct by opening a random evaluation point, i.e., we need to prove the opening point is the root of the polynomial through the equation $f(x)-b=(x-a)\cdot{q(x)}$, where $q(x)$ is the quotient polynomial. Here is why KZG requires the pairing. A pairing (bilinear) allows we map the elements in two groups to the elements in a target group, denoted by $e: G_1\times{G_2}\rightarrow{G_T}$. For example, given $x\in{G_1},y\in{G_2},z\in{G_T}$ and $z=xy$, we can check $g^z=g^{xy}$ using the pairing through 

$$
e(g_1^x,g_2^y)=e(g_1,g_2)^{xy}=e(g_1,g_2)^z=e(g_1,g_2^z)
$$

The pairing normally relies on the assumption of the elliptic curve, which is why KZG requires a pairing-friendly group. After we commit to a polynomial using KZG, what we get is a point on the elliptic curve. Now we can verify the KZG commitment is correct given the commitment to the quotient polynomial and the opening point by checking

$$
e(g_1^{f(\epsilon)}/g_1^b,g_2)=e(g_1^{q(\epsilon)},g_2^{\tau-a})
$$

where $f(a)=b$. If we use the mask polynomial technique, the pairing will become

$$
e(g_1^{f(\epsilon)}h_1^{\hat{f}(\epsilon)}/(g_1^bh_1^r),g_2)=e(g_1^{q(\epsilon)}h_1^{\hat{q}(\epsilon)},g_2^{\tau-a})
$$

It is worth noting we can reveal the committed evaluation $g_1^bh_1^r$ instead of $b$ to hide the actual value. This variant does not violate the soundness of KZG due to the binding property of Pedersen commitment.

## KZG Batch Opening Scheme

Since the pairing is an expensive computation, we want to reduce the pairing operations to optimize the computing time. The original KZG opening scheme requires one pairing for each opening evaluation point. That means opening $$ evaluation points for $m$ polynomials requires $mn$ pairings. One intuitive optimization is linearly combine the polynomials for the same evaluation point and prove the summed polynomial is correct. More precisely, given polynomials $\{f_1,f_2,f_3,\dots,f_m\}$, the prover and the verifier run the following protocol

1. Prover commits to all polynomials and publishes the commitments
2. Verifier sends a random challenge $\gamma$ to linearly combine the polynomials
3. Prover computes $w=\sum_{i=1}^m\gamma^{i-1}f_i$ 
4. Verifier sends a random evaluation point $\zeta$
5. Prover opens $\{f_i\}$ at $\zeta$, computes the quotient polynomial $q(x)$ such that $q=w/(x-\zeta)$, commits to $q$ and publish its commitment
6. Verifier checks
   * the evaluations of $\{f_i\}$ and $q$ at $\zeta$ are correct
   * $w$ is constructed correctly through $\sum_{i=1}^m\gamma^{i-1}f_i(\zeta)=q(\zeta)\cdot(\zeta^n-1)$

The point of this optimization is introduced in [GWC19](https://eprint.iacr.org/2019/953). Boneh et al. introduced another way to reduce the verifying time by moving some of the verifier's work to the prover's in [this paper](https://eprint.iacr.org/2020/081). If you want to know more about the batch opening techniques, there is a paper named [fflonk](https://eprint.iacr.org/2021/1167). The basic idea of fflonk is instead of opening multiple polynomials at one point, opening one polynomial at multiple points. This might sound similar as the idea in GWC19, but they leveraged the properties of FFT to reduce the computing further.

## The Zero-Knowledge Extension

Although a Pedersen commitment provides perfect hiding, the KZG commitment still leaks the information of the opening evaluation point. To avoid this, we can open the committed value of the evaluation. However, this solution may not satisfy some cases, e.g., when linearly combining the evaluations through the batch opening scheme, the summation of the random factors of the committed evaluations does not equal the random factor of the commitment to the quotient polynomial. Boneh et al. introduced a solution, the zero-knowledge extension of the KZG commitment, in [this post](https://hackmd.io/@dabo/B1U4kx8XI). The basic idea is interpolating $t$ more points of the original polynomial, where $t$ is the number of the opening points. Note after interpolating $t$ more points, we can construct a simulator to generate the transcript that is computationally indistinguishable from the transcript produced by the prover. For example, if we want to open $f$ at one point, then we generate two random numbers $\alpha,\beta$ and incrementally interpolate $f$ such that $f(\alpha)=\beta$. And the prover and the verifier should open $f$ at points outside the domain of $f$ to avoid leaking the information of the evaluation.
