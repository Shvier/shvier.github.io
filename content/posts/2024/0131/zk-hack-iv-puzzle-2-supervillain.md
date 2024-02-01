+++
title = 'ZK Hack IV Puzzle 2: Supervillain'
date = 2024-01-31T14:41:24-05:00
tags = [
]
categories = [
]
series = [
]
isDraft = false
+++

>Bob has been designing a new optimized signature scheme for his L1 based on BLS signatures. Specifically, he wanted to be able to use the most efficient form of BLS signature aggregation, where you just add the signatures together rather than having to delinearize them. In order to do that, he designed a proof-of-possession scheme based on the B-KEA assumption he found in the the Sapling security analysis paper by Mary Maller [^1]. Based the reasoning in the Power of Proofs-of-Possession paper [^2], he concluded that his scheme would be secure. After he deployed the protocol, he found it was attacked and there was a malicious block entered the system, fooling all the light nodes...

## Puzzle Explanation

#### BLS Signature
BLS signature is a cryptographic protocol that uses a pairing-friendly elliptic curve to implement the digital signature algorithm. Like ElGamal signature based on the hardness of discrete logarithm problem, BLS relies on the property of an elliptic curve that it is infeasible to reverse the computation of a point, or find \\(s\\) such that \\(g^s=p\\) given \\(g\\) and \\(p\\), where \\(g\\) is a generator of the curve group and \\(p\\) is a point on the curve. Note there is no exponent calculation in elliptic curve, I just use this notation. We can say \\(p\\) is the public key while \\(s\\) is the secret. The signing algorithm is \\(\sigma=H(m)^s\\), where \\(\sigma\\) is the signature, \\(H\\) is a hash function and \\(m\\) is the message we want to sign; the verification uses a bilinear pairing: \\(e(p,H(m))\stackrel{?}{=}e(g,\sigma)\\). The equation holds because \\(e(p,H(m))=e(g^s,H(m))=e(g,H(m)^s)=e(g,\sigma)\\). For more details on why pairing can work in this way, read [this paper](https://static1.squarespace.com/static/5fdbb09f31d71c1227082339/t/5ff394720493bd28278889c6/1609798774687/PairingsForBeginners.pdf).

#### BLS Signature Aggregation
One of the powerful features BLS provides is multi-signing, which enables us to aggregate several individual signatures to verify them at once to reduce computation and data transmission. To do so, add all the signatures to get a new signature and the public keys to get a new key, and, that is it! This works because BLS signature is homomorphic additive. Specifically, assume we add two public keys \\(p_1,p_2\\) and two signatures \\(\sigma_1,\sigma_2\\), we can find that \\(e(p_1+p_2,H(m))=e(g^{s_1},H(m))+e(g^{s_2},H(m))=e(g,H(m)^{s_1})+e(g,H(m)^{s_2})=e(g,\sigma_1+\sigma_2)\\).

#### Rogue Key Attack
In the previous section, we explained how BLS signature aggregation works. Due to its homomorphic addition, an adversary can forge others' signatures to pretend they are signing the message together. The idea is the attacker chooses a secret and the corresponding public key can cancel all the other public keys, e.g., \\(s^\prime=\alpha-\sum{s_i}\\), so that the multi-signature becomes \\(H(m)^{s^\prime+\sum{s_i}}=H(m)^\alpha\\) and the aggregated public key becomes \\(p^\prime+\sum{p_i}=g^\alpha\\). This way, the adversary successfully fools others. That is the reason why we need to delinearize the individual signatures when aggregation. There is also [a modified version of BLS signature](https://crypto.stanford.edu/~dabo/pubs/papers/BLSmultisig.html) that aims to fix this issue.

#### B-KEA
The B-KEA is the bilinear pairing edition of the KEA, knowledge-of-exponent assumption. Roughly speaking, KEA describes a similar computational Diffie-Hellman problem for the theory of zero knowledge, but the difference is the prover does not need to show the exponent. Instead, he proves the knowledge of that exponent. For example, if a malicious prover wants to show the knowledge of \\(c\\) that \\(y=g^c\\), he can open \\(y^b=(g^c)^b\\) and \\(g^b\\). Obviously, it is not such hard as CDH, so there are revisions to this assumption. For more information, read [this paper](https://eprint.iacr.org/2004/008.pdf).  
Back to the B-KEA, the assumption says showing \\(C, \hat{C}\\) such that \\(e(C,h)=e(g,\hat{C})\\) proves \\(s_1\\) and \\(s_2\\) are identical where \\((C,\hat{C})=(g^{s_1},h^{s_2})\\) [^3] (The original assumption describes this statement more rigorously but this is a simple version to understand the assumption). 

## The Breakdown

From the description of the B-KEA, we can see the assumption shows the two numbers are identical rather than the knowledge of the numbers per se. Thus, Bob's implementation cannot ignore the delinearization when aggregating several signatures. Another mistake he makes is the way of signing is simple to be forged. He only multiplies the sequence number by the signature, \\(\sum{R\cdot{(i+1)}\cdot{s_i}}\\). One solution to prevent the attack is to make each coefficient different when aggregating, e.g., \\(\sum{H(p_i)\cdot{s_i}}\\), so that the adversary cannot cancel others' signatures because of the unequal coefficients (Actually this is the idea of the modified version of BLS signature mentioned above).

## The Solution

Based on the above description, our solution came out:
1. Create a secret key and compute the corresponding proof of knowledge key
    ```rust
    let secret_hack = Fr::from(123);
    // R*(n+1)*s
    let pok_hack = derive_point_for_pok(new_key_index).mul(secret_hack);
    ```
2. Compute the public key, \\(pk\\_hack-\sum{pk_i}\\), to cancel others
    ```rust
    let pk_hack = G1Affine::generator().mul(secret_hack);
    let new_key = public_keys
        .iter()
        .fold(G1Projective::from(pk_hack), |acc, (pk, _)| acc - pk)
        .into_affine();
    ```
3. When aggregating the adversary's signature, we add \\(R\cdot(n+1)\cdot{secret\\_hack}\\). The aggregated signature becomes: \\(R\cdot(n+1)\cdot(secret\\_hack+\sum{s_i})=R\cdot(n+1)\cdot{secret\\_hack}+\sum{s_i\cdot{R\cdot(n+1)}}\\). Recall that \\(\pi_i=s_i\cdot{R}\cdot(i+1)\\), so the second term of the equation becomes \\(\sum{\pi_i\cdot(n+1)\cdot(i+1)^{-1}}\\)
    ```rust
    let new_proof = public_keys
        .iter()
        .enumerate()
        .map(|(i, (_, proof))|
            // pi*(n+1)*(i+1)^-1
            proof.mul(Fr::from(new_key_index as u64 + 1) * Fr::from(i as u64 + 1).inverse().unwrap())
        )
        .fold(pok_hack, |acc, proof|
            // R*(n+1)*s - sum_{pi*(n+1)*(i+1)-1}
            acc - proof
        )
        .into_affine();
    ```
4. Finally, sign the message with the adversary's private key
    ```rust
    let aggregate_signature = bls_sign(secret_hack, message);
    ```


[^1]: https://github.com/zcash/sapling-security-analysis/blob/master/MaryMallerUpdated.pdf 
[^2]: https://rist.tech.cornell.edu/papers/pkreg.pdf
[^3]: https://eprint.iacr.org/2017/599.pdf
