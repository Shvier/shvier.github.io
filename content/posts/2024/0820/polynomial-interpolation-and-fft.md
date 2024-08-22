+++
title = 'Polynomial Interpolation and FFT'
date = 2024-08-20T14:47:41-04:00
tags = [
]
categories = [
]
series = [
]
isDraft = true
+++

A polynomial can be represented in two forms: the coefficients, and the evaluations (or point-value). Polynomial interpolation is to construct polynomial from the point values. There are three well-known ways to interpolate a polynomial: the Lagrange interpolation, the Newton interpolation, and the Vandermonde matrix. The biggest difference between Lagrange and Newton is Newton's is faster for incremental interpolation while Lagrange's is more efficient for the same set of points. However, the approaches of Lagrange and Newton take $O(n^2)$ time and Vandermonde takes $O(n^3)$, but the time complexity can be boosted to $O(n\log{n})$ with the help of the fast Fourier transform (FFT), strictly, the inverse FFT (IFFT).

The basic idea of FFT exploits divide and conquer. That is, a polynomial can be decomposed into two parts with half the degree, one part records the coefficients in odd degrees while the other is for the coefficients in even degrees. Suppose $d$ is the power of two; given a polynomial $f\in\mathbb{F}_{\lt{d}}[X]$ and let $a_i$ denote the coefficient of $f$, we have

$$
\begin{align}
f&=a_0+a_1x+a_2x^2+\cdots+a_{d-1}x^{d-1} \\
&=a_0+a_2x^2+\cdots+a_{d-2}x^{d-2}+x\cdot(a_1+a_3x^2+\cdots+a_{d-1}x^{d-2}) \\
&=f_E(x)+x\cdot{f_O(x)}
\end{align}
$$

It is clear that $f_E$ and $f_O$ have half of the degree $d$ and half of the possible values of $x$ (call it domain). And if we know the evaluations of $f_E(x),f_O(x)$, we can compute $f(x),f(-x)$ with one addition and one multiplication. That means we successfully halve the computation of evaluating $f$ for all possible $x$. By recursively performing the same process, we can get one one-degree polynomial and one constant polynomial in $\log{d}$ steps, so the computation is reduced to logarithm time. To demonstrate the algorithm with a concrete example, I will use the data from [Vitalik's post about FFT](https://web.archive.org/web/20231102070604/https://vitalik.ca/general/2019/05/12/fft.html). Given the polynomial $f(x)=3+x+4x^2+x^3+5x^4+9x^5+2x^6+6x^7$ and the domain $[1,85,148,111,336,252,189,226]$, we have

$$
\begin{align}
f(x)&=3+x+4x^2+x^3+5x^4+9x^5+2x^6+6x^7 \\
&=3+4x^2+5x^4+2x^6+x\cdot(1+x^2+9x^4+6x^6) \\
&=3+4\chi+5\chi^2+2\chi^3+x\cdot(1+\chi+9\chi^2+6\chi^3) \\
&=3+5\chi^2+\chi(4+2\chi^2)+x\cdot(1+9\chi^2+\chi\cdot(1+6\chi^2)) \\
&=3+5\varkappa+\chi(4+2\varkappa)+x\cdot(1+9\varkappa+\chi\cdot(1+6\varkappa))
\end{align}
$$

where $\chi=x^2,\varkappa=\chi^2=x^4$. We can observe that $f$ is decomposed into several one-degree and constant polynomials in 3 steps, which means we can evaluate the polynomial for all the points on the domain in logarithm time. You might have questions about how it relates to polynomial interpolation. The answer is if there exists an algorithm allowing us to convert the coefficients into the evaluations efficiently, then the interpolation can also be done quickly by inversing the algorithm. 

We can see the algorithm requires the degree of the polynomial to be the power of two. This seems no problem because we can zero the coefficients for the polynomial less than the degree or sparse. The challenge is the evaluation points must have some special values to satisfy the recursion, i.e., the value of squaring $x$ multiple times should be on the same domain. This means FFT works on a finite field under multiplication and the order of the generator is the power of two, which is exactly the property of the roots of unity. In the above example, $85$ is the root of unity with order $8$, and we can verify that $85$ modulo $337$ satisfies the requirement. We say $85$ is an eighth root of unity modulo $337$.

Based on the above knowledge, now we can convert a polynomial between the coefficients and the point values in logarithm time. Let us see the FFT first and the IFFT later using a concrete example. To evaluate $f(x)=3+x+4x^2+x^3+5x^4+9x^5+2x^6+6x^7$ over the domain $[1,85,148,111,336,252,189,226]$, we apply the algorithm as follows:

1. Decompose $f(x)$ into $f_E^{[1]}(x),f_O^{[1]}(x)$ such that

$$
f_E^{[1]}(x)=3+4x+5x^2+2x^3 \\
f_O^{[1]}(x)=1+x+9x^2+6x^3
$$

where $x\in\{1,148,336,189\}$. Why is $x$ of $f_E^{[1]}$ and $f_O^{[1]}$ on this domain? Note the $x$ of $f_E$ and $f_O$ is $x^2$ on the original domain, which means the new $x$ is $85,85^2,85^4,85^6\mod{337}$. Given the evaluations of $f_E^{[1]},f_O^{[1]}$, we can evaluate $f$ over the domain through the following equations

$$
f(1)=f_E^{[1]}(1)+f_O^{[1]}(1),f(-1)=f(336)=f_E^{[1]}(1)-f_O^{[1]}(1) \\
f(85)=f_E^{[1]}(148)+85\cdot{f_O^{[1]}(148)},f(-85)=f(252)=f_E^{[1]}(148)-85\cdot{f_O^{[1]}(148)} \\
f(148)=f_E^{[1]}(336)+148\cdot{f_O^{[1]}(336)},f(-148)=f(189)=f_E^{[1]}(336)-148\cdot{f_O^{[1]}(336)} \\
f(111)=f_E^{[1]}(189)+111\cdot{f_O^{[1]}(189)},f(-111)=f(226)=f_E^{[1]}(189)-111\cdot{f_O^{[1]}(189)}
$$

2. Recursively decompose the polynomials using the same method as the following figure depicts 

{{< mermaid >}}
graph TB
    A($f$)-->B1("$f_E^{[1]}=3+4x+5x^2+2x^3$")
    A-->B2("$f_O^{[1]}=1+x+9x^2+6x^3$")
    B1-->C1("$f_E^{[2,1]}=3+5x$")
    B1-->C2("$f_O^{[2,2]}=4+2x$")
    B2-->C3("$f_E^{[2,3]}=1+9x$")
    B2-->C4("$f_O^{[2,4]}=1+6x$")
    C1-->D1("$f_E^{[3,1]}=3$")
    C1-->D2("$f_O^{[3,2]}=5$")
    C2-->D3("$f_E^{[3,3]}=4$")
    C2-->D4("$f_O^{[3,4]}=2$")
    C3-->D5("$f_E^{[3,5]}=1$")
    C3-->D6("$f_O^{[3,6]}=9$")
    C4-->D7("$f_E^{[3,7]}=1$")
    C4-->D8("$f_O^{[3,8]}=6$")
{{< /mermaid >}}

3. Evaluate the polynomials from the bottom to the root

Finally, we can get the evaluations $[31, 70, 109, 74, 334, 181, 232, 4]$. Before explaining how the IFFT works, I want to introduce another representation of polynomial evaluation, the matrix, to help us understand the IFFT. When evaluating a polynomial with degree $n-1$, we can treat the computation as the mulplication of two matrices as follows:

$$
Y_n=\begin{bmatrix}
y_0 \\
y_1 \\
y_2 \\
\vdots \\
y_{n-1}
\end{bmatrix}=
\begin{bmatrix}
1 & 1 & 1 & \cdots & 1\\
1 & x & x^2 & \cdots & x^{n-1} \\
1 & x^2 & x^4 & \cdots & x^{2(n-1)} \\
\vdots & \vdots & \vdots & \ddots & \vdots \\
1 & x^{n-1} & x^{2(n-1)} & \cdots & x^{(n-1)(n-1)} \\
\end{bmatrix}
\begin{bmatrix}
a_0 \\
a_1 \\
a_2 \\
\vdots \\
a_{n-1}
\end{bmatrix}
$$

where $a_i$ is the coefficient and $y_i$ is the evaluation. It is clear that we can use the following equation to compute $\{a_i\}$ from $\{y_i\}$:

$$
\begin{bmatrix}
a_0 \\
a_1 \\
a_2 \\
\vdots \\
a_{n-1}
\end{bmatrix}=
\begin{bmatrix}
1 & 1 & 1 & \cdots & 1\\
1 & x & x^2 & \cdots & x^{n-1} \\
1 & x^2 & x^4 & \cdots & x^{2(n-1)} \\
\vdots & \vdots & \vdots & \ddots & \vdots \\
1 & x^{n-1} & x^{2(n-1)} & \cdots & x^{(n-1)(n-1)} \\
\end{bmatrix}^{-1}
\begin{bmatrix}
y_0 \\
y_1 \\
y_2 \\
\vdots \\
y_{n-1}
\end{bmatrix}
$$

Suppose $M_n=
\begin{bmatrix}
1 & 1 & 1 & \cdots & 1\\
1 & x & x^2 & \cdots & x^{n-1} \\
1 & x^2 & x^4 & \cdots & x^{2(n-1)} \\
\vdots & \vdots & \vdots & \ddots & \vdots \\
1 & x^{n-1} & x^{2(n-1)} & \cdots & x^{(n-1)(n-1)} \\
\end{bmatrix}$. There is a lemma telling us the inverse of $M_n$ is

$$
M_n^{-1}=\frac{1}{n}
\begin{bmatrix}
1 & 1 & 1 & \cdots & 1\\
1 & x^{-1} & x^{-2} & \cdots & x^{-(n-1)} \\
1 & x^{-2} & x^{-4} & \cdots & x^{-2(n-1)} \\
\vdots & \vdots & \vdots & \ddots & \vdots \\
1 & x^{-(n-1)} & x^{-2(n-1)} & \cdots & x^{-(n-1)(n-1)} \\
\end{bmatrix}
$$

The correctness of the lemma is natural. We can denote the element of the product of $M_n$ and $M_n^{-1}$ by 

$$
\sum_{j=0}^{n-1}x^{i\cdot{j}}\frac{x^{-j\cdot{i^\prime}}}{n}=\frac{1}{n}\sum_{j=0}^{n-1}x^{(i-i^\prime)\cdot{j}}
$$

where $i,i^\prime\in[0,n)$. When $i=i^\prime$, the result is $1$, which means the elements on the diagonal of the product are $1$; when $i\ne{i^\prime}$, the result is $0$, because $x^n-1=0=(x-1)(1+x+x^2+x^3+\cdots+x^{n-1})\Rightarrow{1+x+x^2+x^3+\cdots+x^{n-1}=0}$ and let $x=x^{i-i^\prime}$.

Based on the above knowledge, we can compute $\{a_i\}$ from $\{y_i\}$ by multiplying $M_n^{-1}$ and $Y_n$. We have

$$
M_n^{-1}
\begin{bmatrix}
y_0 \\
y_1 \\
y_2 \\
\vdots \\
y_{n-1}
\end{bmatrix}=
\frac{1}{n}
\begin{bmatrix}
\sum_{i=0}^{n-1}{y_i} \\
\sum_{i=0}^{n-1}{y_ix^{-i}} \\
\sum_{i=0}^{n-1}{y_ix^{-(2i)}} \\
\vdots \\
\sum_{i=0}^{n-1}{y_ix^{-(n-1)i}} \\
\end{bmatrix}
$$

It might not be obivious to see how to relate the FFT with this, as we need to rearrange the equations. Let us start with $\sum_{i=0}^{n-1}{y_ix^{-i}}$. Recall $x$ is an $n$-th root of unity, which means $(x^n)^k=1$, where $k$ is an integer. So we have

$$
\begin{align}
\sum_{i=0}^{n-1}{y_ix^{-i}}&=x^n\cdot\sum_{i=0}^{n-1}{y_ix^{-i}}\\
&=x^n(y_0x^0+y_1x^{-1}+y_2x^{-2}+y_3x^{-3}+\cdots+y_{n-1}x^{-(n-1)}) \\
&=y_0x^n+y_1x^{n-1}+y_2x^{n-2}+y_3x^{n-3}+\cdots+y_{n-1}x^{1}
\end{align}
$$

$$
\begin{align}
\sum_{i=0}^{n-1}{y_ix^{-2i}}&=x^{2n}\cdot\sum_{i=0}^{n-1}{y_ix^{-2i}} \\
&=x^{2n}(y_0x^0+y_1x^{-2}+y_2x^{-4}+y_3x^{-6}+\cdots+y_{n-1}x^{-2(n-1)}) \\
&=y_0x^{2n}+y_1x^{2(n-1)}+y_2x^{2(n-2)}+y_3x^{2(n-3)}+\cdots+y_{n-1}x^{2} \\
\end{align}
$$

and so on and so forth. Interestingly, the product of $M_n^{-1}Y_n$ is exactly the same as the product of $\frac{1}{n}M_nY_n^\prime$, where 

$$
Y_n=
\begin{bmatrix}
y_0 \\
y_{n-1} \\
y_{n-2} \\
y_{n-3} \\
\vdots \\
y_1
\end{bmatrix}
$$

Therefore, the implementation of the IFFT is quite clear: run the FFT for $\{y_i\}$ first, then let each element of \{y_i\} multiply the multiplicative inverse of $n$ modulo the domain (337 for the above example). (Remember to reorder $\{y_i\}$)
